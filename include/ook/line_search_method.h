#ifndef OOK_LINE_SEARCH_METHOD_H_
#define OOK_LINE_SEARCH_METHOD_H_

#include <iostream>
#include <iomanip>
#include <boost/numeric/ublas/matrix.hpp>

#include "ook/norms.h"
#include "ook/message.h"
#include "ook/state.h"
#include "ook/call_selector.h"
#include "ook/line_search/more_thuente.h"

namespace ook{

namespace detail{

template <typename T>
typename T::value_type
inner_product(const T& x, const T& y){
    typedef typename T::value_type value_type;
    return std::inner_product(x.begin(), x.end(), y.begin(), value_type(0.0));
}

} // ns detail

template <typename Scheme, typename F, typename X, typename Options, typename Observer>
std::tuple<ook::message, X>
line_search_method(F objective_function, X x, const Options& opts, Observer& observer)
{
    typedef typename X::value_type real_type;
    typedef typename Scheme::state_type state_type;

    typedef decltype(objective_function(x)) result_type;
    typedef detail::call_selector<F, X, state_type, std::tuple_size<result_type>::value> caller_type;

    const real_type epsilon = std::numeric_limits<real_type>::epsilon();
    const real_type dx_eps = sqrt(epsilon);
    const real_type df_eps = exp(log(epsilon)/3);

    state_type s = Scheme::initialise(objective_function, x);
    X dx(x.size());
    s.iteration = 0;
    uint nfev_total = 0;

    observer(s);
    do {
        s.tag = detail::state_tag::iterate;
        // Get descent direction and set up line search procedure.
        X p = Scheme::descent_direction(s);
        // do line search
        uint nfev = 0;
        s.a = 1.0;
        // take a reference to the state variable, ensuring that fx and dfx get updated
        auto phi = [&nfev, &s, &x, &p, objective_function](const real_type& a){
            ++nfev;
            caller_type::call(objective_function, x + a * p, s);
            return std::make_pair(s.fx, detail::inner_product(s.dfx, p));
        };

        // Store current fx value since line search overwrites the state values.
        const real_type fxk = s.fx;
        real_type dfx_dot_p = detail::inner_product(s.dfx, p);
        std::tie(s.msg, s.a, s.fx, dfx_dot_p) = ook::line_search::more_thuente()(phi, s.fx, dfx_dot_p, s.a, opts);

        if (s.msg != ook::message::convergence){
            break;
        }
        dx = s.a * p;
        x += dx;
        nfev_total += nfev;
        ++s.iteration;

        // Convergence criteria assessment base on p306 in Gill, Murray and Wright.
        const double theta = epsilon * (1 + fabs(s.fx));
        const bool u1 = (fxk - s.fx) <= theta;
        const bool u2 = ook::norm_infinity(dx) <=  dx_eps * (1.0 + ook::norm_infinity(x));
        const bool u3 = ook::norm_infinity(s.dfx) <= df_eps * (1.0 + fabs(s.fx));

        observer(s);
        if ((u1 & u2) || u3){
            s.msg = ook::message::convergence;
            break;
        }

        s = Scheme::update(s);

    } while(true);

    s.tag = detail::state_tag::final;
    observer(s);
    return std::make_pair(s.msg, x);
}

} // ns ook
#endif