// Copyright 2013 Harry Hill
//
// This file is part of ook.
//
// ook is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// ook is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.

// You should have received a copy of the GNU Lesser General Public License
// along with ook.  If not, see <http://www.gnu.org/licenses/>.

# ifndef OOK_FACTORISATIONS_LDLT_H_
# define OOK_FACTORISATIONS_LDLT_H_

#include <vector>
#include <stdexcept>

#include <boost/numeric/ublas/vector.hpp>
#include <boost/numeric/ublas/matrix.hpp>
#include <boost/numeric/ublas/vector_proxy.hpp>
#include <boost/numeric/ublas/matrix_proxy.hpp>
#include <boost/numeric/ublas/io.hpp>
#include <boost/numeric/ublas/assignment.hpp>
#include <boost/numeric/ublas/triangular.hpp>

#include "ook/factorisations/tools.h"

namespace ook{

namespace factorisations{

/// \brief LDL^t factorisation.
template <typename Matrix>
Matrix
ldlt(Matrix A)
{
    using namespace boost::numeric::ublas;

    typedef typename Matrix::size_type size_type;
    typedef typename Matrix::value_type real_type;

    const size_type n = A.size1();

    Matrix L(n, n, 0.0);
    Matrix c(n, n, 0.0);
    for (size_type j = 0; j < n; ++j){

        real_type cqq;
        size_type q;
        std::tie(q, cqq) = tools::max_magnitude_diagonal(matrix_range<Matrix>(c, range(j, n), range(j, n)));

        // Pivoting
        if (q != j){
            matrix_row<Matrix> rowq(A, q);
            matrix_row<Matrix> rowj(A, j);
            rowq.swap(rowj);

            matrix_row<Matrix> colq(A, q);
            matrix_row<Matrix> colj(A, j);
            colq.swap(colj);
        }

        c(j, j) = A(j, j);
        for (size_type s = 0; s < j; ++s){
            c(j, j) -= L(s, s) * std::pow(L(j, s), 2);
        }
        L(j, j) = c(j, j);

        for (size_type i = j + 1; i < n; ++i){
            c(i, j) = A(i, j);
            for (size_type s = 0; s < j; ++s){
                c(i, j) -= L(s, s) * L(i, s) * L(j, s);
            }
            L(i, j) = c(i, j) / L(j, j);
        }
    }
    return L;
}

} // ns factorisations

} // ns ook

#endif
