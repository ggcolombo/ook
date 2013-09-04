#include <cmath>
#include <algorithm>

#define max(x, y) std::max(x, y)
#define min(x, y) std::min(x, y)

int dcstep_(double& stx, double& fx, double& dx, double& sty, double& fy, double& dy, double& stp, double& fp, double& dp, bool& brackt, double& stpmin, double& stpmax)
{
    /* System generated locals */
    double d__1, d__2, d__3;

    /* Local variables */
    static double sgnd, stpc, stpf, stpq, p, q, gamma, r__, s, theta;

/*	This subroutine computes a safeguarded step for a search
	procedure and updates an interval that contains a step that
	satisfies a sufficient decrease and a curvature condition.

	The parameter stx contains the step with the least function
	value. If brackt is set to .true. then a minimizer has
	been bracketed in an interval with endpoints stx and sty.
	The parameter stp contains the current step.
	The subroutine assumes that if brackt is set to .true. then 

		min(stx,sty) < stp < max(stx,sty),

	and that the derivative at stx is negative in the direction
	of the step.

	The subroutine statement is

		subroutine dcstep(stx,fx,dx,sty,fy,dy,stp,fp,dp,brackt,stpmin,stpmax)

	where

	stx is a double precision variable.
		On entry stx is the best step obtained so far and is an
			endpoint of the interval that contains the minimizer.
		On exit stx is the updated best step.

	fx is a double precision variable.
		On entry fx is the function at stx.
		On exit fx is the function at stx.

	dx is a double precision variable.
		On entry dx is the derivative of the function at
			stx. The derivative must be negative in the direction of
			the step, that is, dx and stp - stx must have opposite signs.
		On exit dx is the derivative of the function at stx.

	sty is a double precision variable.
		On entry sty is the second endpoint of the interval that contains 
			the minimizer.
		On exit sty is the updated endpoint of the interval that contains 
			the minimizer.

	fy is a double precision variable.
		On entry fy is the function at sty.
		On exit fy is the function at sty.

	dy is a double precision variable.
		On entry dy is the derivative of the function at sty.
		On exit dy is the derivative of the function at the exit sty.

	stp is a double precision variable.
		On entry stp is the current step. If brackt is set to .true.
			then on input stp must be between stx and sty.
		On exit stp is a new trial step.

	fp is a double precision variable.
		On entry fp is the function at stp
		On exit fp is unchanged.

	dp is a double precision variable.
		On entry dp is the the derivative of the function at stp.
		On exit dp is unchanged.

	brackt is an bool variable.
		On entry brackt specifies if a minimizer has been bracketed.
			Initially brackt must be set to .false.
		On exit brackt specifies if a minimizer has been bracketed.
			When a minimizer is bracketed brackt is set to .true.

	stpmin is a double precision variable.
		On entry stpmin is a lower bound for the step.
		On exit stpmin is unchanged.

	stpmax is a double precision variable.
		On entry stpmax is an upper bound for the step.
		On exit stpmax is unchanged.

	MINPACK-1 Project. June 1983 
	Argonne National Laboratory.
	Jorge J. More' and David J. Thuente.

	MINPACK-2 Project. November 1993. 
	Argonne National Laboratory and University of Minnesota.
	Brett M. Averick and Jorge J. More'.
	*/

    sgnd = dp * (dx / fabs(dx));
	/*	First case: A higher function value. The minimum is bracketed.
	If the cubic step is closer to stx than the quadratic step, the
	cubic step is taken, otherwise the average of the cubic and 
	quadratic steps is taken. */
    if (fp > fx) {
		theta = (fx - fp) * 3. / (stp - stx) + dx + dp;
		/* Computing MAX */
		d__1 = fabs(theta), d__2 = fabs(dx), d__1 = max(d__1,d__2), d__2 = fabs(dp);
		s = max(d__1,d__2);
		/* Computing 2nd power */
		d__1 = theta / s;
		gamma = s * sqrt(d__1 * d__1 - dx / s * (dp / s));
		if (stp < stx) {
	    	gamma = -gamma;
		}
		p = gamma - dx + theta;
		q = gamma - dx + gamma + dp;
		r__ = p / q;
		stpc = stx + r__ * (stp - stx);
		stpq = stx + dx / ((fx - fp) / (stp - stx) + dx) / 2. * (stp - stx);
		if ((d__1 = stpc - stx, fabs(d__1)) < (d__2 = stpq - stx, fabs(d__2))){
	    	stpf = stpc;
		} else {
	    	stpf = stpc + (stpq - stpc) / 2.;
		}
		brackt = true;
	/*	Second case: A lower function value and derivatives of opposite
	sign. The minimum is bracketed. If the cubic step is farther from
	stp than the secant step, the cubic step is taken, otherwise the
	secant step is taken. */
    } else if (sgnd < 0.) {
    	theta = (fx - fp) * 3. / (stp - stx) + dx + dp;
		/* Computing MAX */
		d__1 = fabs(theta), d__2 = fabs(dx), d__1 = max(d__1,d__2), d__2 = fabs(dp);
		s = max(d__1,d__2);
		/* Computing 2nd power */
		d__1 = theta / s;
		gamma = s * sqrt(d__1 * d__1 - dx / s * (dp / s));
		if (stp > stx) {
	    	gamma = -gamma;
		}
		p = gamma - dp + theta;
		q = gamma - dp + gamma + dx;
		r__ = p / q;
		stpc = stp + r__ * (stx - stp);
		stpq = stp + dp / (dp - dx) * (stx - stp);
		if ((d__1 = stpc - stp, fabs(d__1)) > (d__2 = stpq - stp, fabs(d__2))){
			stpf = stpc;
		} else {
			stpf = stpq;
		}
		brackt = true;
	/* Third case: A lower function value, derivatives of the same sign,
	and the magnitude of the derivative decreases. */
    } else if (fabs(dp) < fabs(dx)) {
	/* 	The cubic step is computed only if the cubic tends to infinity
		in the direction of the step or if the minimum of the cubic
		is beyond stp. Otherwise the cubic step is defined to be the
		secant step. */
		theta = (fx - fp) * 3. / (stp - stx) + dx + dp;
		/* Computing MAX */
		d__1 = fabs(theta), d__2 = fabs(dx), d__1 = max(d__1,d__2), d__2 = fabs(dp);
		s = max(d__1,d__2);
		/* The case gamma = 0 only arises if the cubic does not tend
		to infinity in the direction of the step.*/
		d__3 = theta / s;
		d__1 = 0., d__2 = d__3 * d__3 - dx / s * (dp / s);
		gamma = s * sqrt((max(d__1,d__2)));
		if (stp > stx) {
	    	gamma = -gamma;
		}
		p = gamma - dp + theta;
		q = gamma + (dx - dp) + gamma;
		r__ = p / q;
		if (r__ < 0. && gamma != 0.) {
	    	stpc = stp + r__ * (stx - stp);
		} else if (stp > stx) {
	    	stpc = stpmax;
		} else {
	    	stpc = stpmin;
		}
		stpq = stp + dp / (dp - dx) * (stx - stp);
		if (brackt) {
		/* A minimizer has been bracketed. If the cubic step is
		closer to stp than the secant step, the cubic step is
		taken, otherwise the secant step is taken. */
	    if ((d__1 = stpc - stp, fabs(d__1)) < (d__2 = stpq - stp, fabs(d__2))) {
			stpf = stpc;
	    } else {
			stpf = stpq;
	    }
	    if (stp > stx) {
	    	d__1 = stp + (sty - stp) * .66;
	    	stpf = min(d__1,stpf);
	    } else {
	    	/* Computing MAX */
			d__1 = stp + (sty - stp) * .66;
			stpf = max(d__1,stpf);
	    }
	} else {
		/* A minimizer has not been bracketed. If the cubic step is
		farther from stp than the secant step, the cubic step is
		taken, otherwise the secant step is taken. */
	    if ((d__1 = stpc - stp, fabs(d__1)) > (d__2 = stpq - stp, fabs(d__2))) {
	    	stpf = stpc;
	    } else {
	    	stpf = stpq;
	    }
	    stpf = min(stpmax, stpf);
	    stpf = max(stpmin, stpf);
	}
	/* Fourth case: A lower function value, derivatives of the same sign,
	and the magnitude of the derivative does not decrease. If the
	minimum is not bracketed, the step is either stpmin or stpmax,
	otherwise the cubic step is taken. */
    } else {
		if (brackt) {
	    	theta = (fp - fy) * 3. / (sty - stp) + dy + dp;

	    	d__1 = fabs(theta), d__2 = fabs(dy), d__1 = max(d__1,d__2), d__2 = fabs(dp);
	    	s = max(d__1,d__2);

	    	d__1 = theta / s;
	    	gamma = s * sqrt(d__1 * d__1 - dy / s * (dp / s));
	    	if (stp > sty) {
	    		gamma = -gamma;
	    	}
	    	p = gamma - dp + theta;
	    	q = gamma - dp + gamma + dy;
	    	r__ = p / q;
	    	stpc = stp + r__ * (sty - stp);
	    	stpf = stpc;
		} else if (stp > stx) {
	    	stpf = stpmax;
		} else {
	    	stpf = stpmin;
		}
    }
	/* Update the interval which contains a minimizer. */
    if (fp > fx) {
		sty = stp;
		fy = fp;
		dy = dp;
    } else {
		if (sgnd < 0.) {
	    	sty = stx;
	    	fy = fx;
	    	dy = dx;
		}
		stx = stp;
		fx = fp;
		dx = dp;
    }
	/*     Compute the new step. */
    stp = stpf;
} 

