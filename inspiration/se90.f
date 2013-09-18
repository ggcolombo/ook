C      ALGORITHM 695 , COLLECTED ALGORITHMS FROM ACM.
C      THIS WORK PUBLISHED IN TRANSACTIONS ON MATHEMATICAL SOFTWARE,
C      VOL. 17, NO. 3, SEPTEMBER, 1991, PP. 306-312.
c
c
c     Driver for  modified cholesky factorization algorithm.
c
c
      integer n,ndim
      double precision A(100,100)
      double precision Atwo(100,100)
      double precision g(100),E(100)
      double precision maxadd
      integer P(100)
      double precision y(100),b(100),x(100)
      double precision eps,tau1,tau2,sum
      integer ptran(100)
      integer z
      double precision high,low,temp
      logical errfnd
      ndim=100


C     mcheps subroutine computes machine precision,
C     The following line may be replaced by an assignment to eps
C     of  the correct machine precision constant for your machine.

      call mcheps(eps)

C     Tolerances used by modchl:
C     tau1 is used in determining when to switch to phase 2 and
C     tau2 is used in determining the amount to add to the diagonal
C     of the final 2X2 submatrix.

      tau1 = eps ** (1./3.)
      tau2 = eps ** (1./3.)

C     Initial seed for random number generator used to generate test
C     matrices
      z = 1000

C     high and low are the ranges of the eigenvalues for the test matrix
C     to be generated.

      high = 1.0
      low = -1.0

C     The first test problem will have dimension n=4, so that the entire
C     problem can be printed out.

      n = 4

      print *,'TEST PROBLEM #1'
      print *,'Test Matrix of size',n
      print *,'with eigenvalues within the range of ',low,' to ',high

      call mkmat(ndim,n,z,A,high,low,Atwo,g)

      print *,' '
      print *,'Original 4X4 matrix'

      do 25 i=1,n
  25     print 30,(A(i,j),j=1,n)
  30  format (4f20.8)

C     save the original matrix
      do 40 i=1,n
         do 40 j=1,n
 40         Atwo(i,j)=A(i,j)

      call modchl(ndim,n,A,g,eps,tau1,tau2,P,E)

      print *,' '
      print *,'Matrix after factorization with l in the lower triangle'

      do 50 i=1,n
  50     print 30,(A(i,j),j=1,n)

      print *,' '
      print *, 'Iteration  Permutation   Amt added to Aii'
      do 75 i=1,n
  75     print 80,i,P(i),e(i)
  80  format (i2,10x,i2,10x,f12.8)

      maxadd = E(n)

      print *,' '
      print *,'Maximum amount added to the diagonal is',maxadd

C
C     Generate  b for solve (using x(i)=i*2.0)
C
      do 90 i=1,n
         ptran(P(i))=i
 90   continue
      do 100 i=1,n
         Atwo(i,i)=Atwo(i,i)+E(ptran(i))
 100  continue
      do 120 i=1,n
         sum=0.0
         do 110 j=1,n
            sum= sum + Atwo(i,j)*(j*2.0)
 110     continue
         b(i)=sum
 120  continue

C
C     Call solve with A and P from modchl,
C     b is the input vector and x is the result vector
C        s.t.  solve computes (A+E)x=b.
C
      call solve(ndim,n,A,P,x,b,g,y)
C
C     compare the  correct answer to the solution found by solve
C
      errfnd = .false.
      do 130 i=1,n
         if (abs(x(i)-(i*2.0)) .gt. tau1) then
            if (.not. errfnd) then
               errfnd = .true.
               print *,' '
               print *,'Errors in Solve:'
               print *,'element #   correct answer   x (from solve)'
            end if
            temp = i * 2.0
            print 135,i,temp,x(i)
         end if
 130  continue
 135  format  (i3,10x,f8.4,7x,f8.4)


C     The next  test problem has size n=50
C     with eigenvalue range [-10000,-1].

      n = 50
      high = -1.0
      low = -10000.0

      print *,' '
      print *,'TEST PROBLEM #2'
      print *,'Test Matrix of size',n
      print *,'with eigenvalues in the range of ',low,' to ',high


      call mkmat(ndim,n,z,A,high,low,Atwo,g)

C     save the original matrix
      do 140 i=1,n
         do 140 j=1,n
 140         Atwo(i,j)=A(i,j)

      call modchl(ndim,n,A,g,eps,tau1,tau2,P,E)

      maxadd = E(n)

      print *,'Maximum amount added to the diagonal is',maxadd

C
C     Generate  b
C
      do 145 i=1,n
         b(i)=10.0 * i
 145  continue

C
C     Call solve
C
      call solve(ndim,n,A,P,x,b,g,y)
C
C     check the solution found by solve
C
      errfnd = .false.
      do 150 i=1,n
         ptran(P(i))=i
 150   continue
      do 160 i=1,n
         Atwo(i,i)=Atwo(i,i)+E(ptran(i))
 160  continue
      do 180 i=1,n
         sum=0.0
         do 170 j=1,n
            sum= sum + Atwo(i,j)*(x(j))
 170     continue
         if (abs(b(i)-sum) .gt. tau1) then
            if (.not. errfnd) then
               errfnd = .true.
               print *,' '
               print *,'Errors in Solve:'
               print *,'element #    b(i)         b(i)=(A+E)x'
               print *,'            (from input)  (x from solve)'
            end if
            print 135,i,b(i),sum
         end if
 180  continue

      stop
      end
c***********************************************************************
c       mcheps
c***********************************************************************
      subroutine mcheps(eps)
*
      double precision eps
*
      double precision temp
*
      temp = 1.0
*
 20   continue
         temp = temp / 2.0
      if ((1.0 + temp) .ne. 1.0) goto 20
*
      eps = temp * 2.0
*
      return
      end
*
C**********************************************************************
C
C     subroutine name : mkmat
C
C     purpose : Create an n dimensional matrix with eigenvalues
C             in the range of low to high by
C             forming the product q1*q2*q3*d*(q1*q2*q3)transpose,
C             where each qi is a Householder matrix, & each
C             diag element of d is in the desired eigenvalue
C             range.
C
C  input:   ndim  - largest dimension of matrix that will be used
C
C           n     - dimension of matrix
C
C           z     - initial seed for random number generator
C
C           high  - upper bound for eigenvalues of generated matrix
C
C           low   - lower bound for eigenvalues of generated matrix
C
C           q     - n*n work matrix
C
C           d     - n*1 work vector
C
C  output:  A     - generated matrix with eigenvalues in the range
C                   of low to high.
C
C           z     - next integer in the sequence generated by random
C                   number generator.
C
C
C**********************************************************************
*
      subroutine mkmat(ndim,n,z,A,high,low,q,v)
      integer n,ndim,z
      double precision A(ndim,n)
      double precision high,low
      double precision  q(ndim,n),v(n)
*
      integer i,j
      double precision r,drand,rand
      intrinsic abs
*
C     Make an orthonormal matrix A
      call mkorth(A,v,n,ndim,z)
*
*
C     Make an orthonormal matrix q
      call mkorth(q,v,n,ndim,z)
*
*
C     A = A * q
      call matmul(A,q,v,n,ndim)
*
*
C     Make an orthonormal matrix q
      call mkorth(q,v,n,ndim,z)
*
C     A = A * q
      call matmul(A,q,v,n,ndim)
*
*
C
C     q = A transpose
C
      do 20 i=1,n
         do 10 j=1,n
            q(i,j) = A(j,i)
  10     continue
  20  continue
*
*
C     Make a random vector v in the range of low to high
*
      r  = abs(high - low)
*
      do 30 i=1,n
         drand = rand(z)
         v(i) = low + r*drand
  30  continue
*
*
C     Make the first  diag element negative if range is big
*
      if ((high .gt. 100).and. (low .lt. 0)) then
         drand = rand(z)
         v(1) = -1.0 + drand
      end if
*
*
C     multiply  A = A * v
C     where v represents a diagonal matrix stored in a vector
*
      do 50 i=1,n
         do 40 j=1,n
            A(i,j) = A(i,j) * v(j)
  40     continue
  50  continue
*
C     A = A * q
      call matmul(A,q,v,n,ndim)
*
*
      return
      end
*
      subroutine mkorth(q,w,n,ndim,z)
C
C     purpose : make a Househoulder matrix by randomly generating
C               values in the range [-1,1] for an n dimension vector; w,
C               then computing the matrix
C               Q = I - (2/(2norm(w)**2)*w*(wtranspose)).
C     Input :   n,ndim,
C               z - seed for random number generator
C     Output :  w - an n*1 vector with values in the range [-1,1],
C               Q - a Househoulder matrix.
*
*
      integer n,ndim,z
      double precision q(ndim,n),w(n)
*
      double precision drand,norm2,rand
      integer j,k
*
*
      do 10 j=1,n
         drand  = rand(z)
         w(j) = -1.0 + (2.0 * drand)
  10  continue
*
      norm2 = 0.0
      do 20 j=1,n
            norm2 = norm2 + (w(j)**2)
  20  continue
      norm2 = 2.0/norm2
*
      do 40 j=1,n
         do 30 k=1,n
            q(j,k) = norm2 * w(j) * w(k)
            if (j .eq. k) then
               q(j,k) = 1.0 - q(j,k)
            else
                q(j,k) = 0.0 - q(j,k)
            end if
 30      continue
 40   continue
*
      return
      end
*
*
      subroutine matmul(a,b,v,n,ndim)
*
      double precision a(ndim,n), b(ndim,n), v(n)
      integer n,ndim
*
      double precision res
      integer i,j,k
*
      do 40 i=1,n
         do 20 j=1,n
             res = 0.0
             do 10 k=1,n
                res = res + a(i,k)*b(k,j)
  10         continue
             v(j) = res
  20     continue
         do 30 j=1,n
             a(i,j)=v(j)
  30     continue
  40  continue
*
      return
      end
*
*
C***********************************************************************
C     random number generator from:
C
C           Shrage, L.:A More Portable Random Number Generator,
C           ACM Trans. Math. Software, 5: 132-138(1979).
C
C     purpose: generates double precision numbers in the range of 0->1.
C
C     input:  ix  - initial value of seed
C     output: ix  - next integer in the random sequence
C                 in the range of 0 to 2^31 - 1.
C             rand - double precision number in the range of 0 -> 1.
C***********************************************************************
      double precision function rand(ix)
      integer a,p,ix,b15,b16,xhi,xalo,leftlo,fhi,k
      data a/16807/,b15/32768/,b16/65536/,p/2147483647/
*
      xhi=ix/b16
      xalo=(ix-xhi*b16)*a
      leftlo=xalo/b16
      fhi=xhi*a+leftlo
      k=fhi/b15
      ix=(((xalo-leftlo*b16)-p)+(fhi-k*b15)*b16)+k
      if (ix .lt. 0) ix=ix+p
      rand = dfloat(ix)*4.656612875e-10
      return
      end
C*********************************************************************
C
C       subroutine name: modchl
C
C       authors :  Elizabeth Eskow and Robert B. Schnabel
C
C       date    : December, 1988
C
C       purpose : perform a modified cholesky factorization
C                 of the form (Ptranspose)AP  + E = L(Ltranspose),
C       where L is stored in the lower triangle of the
C       original matrix A.
C       The factorization has 2 phases:
C        phase 1: Pivot on the maximum diagonal element.
C            Check that the normal cholesky update
C            would result in a positive diagonal
C            at the current iteration, and
C            if so, do the normal cholesky update,
C            otherwise switch to phase 2.
C        phase 2: Pivot on the minimum of the negatives
C            of the lower gerschgorin bound
C            estimates.
C            Compute the amount to add to the
C            pivot element and add this
C            to the pivot element.
C            Do the cholesky update.
C            Update the estimates of the
C            gerschgorin bounds.
C
C       input   : ndim    - largest dimension of matrix that
C                           will be used
C
C                 n       - dimension of matrix A
C
C                 A       - n*n symmetric matrix (only lower triangular
C            portion of A, including the main diagonal, is used)
C
C                 g       - n*1 work array
C
C                 mcheps - machine precision
C
C                tau1    - tolerance used for determining when to switch
C                          phase 2
C
C                tau2    - tolerance used for determining the maximum
C                          condition number of the final 2X2 submatrix.
C
C
C       output  : L     - stored in the matrix A (in lower triangular
C                           portion of A, including the main diagonal)
C
C                 P     - a record of how the rows and columns
C                         of the matrix were permuted while
C                         performing the decomposition
C
C                 E     - n*1 array, the ith element is the
C                         amount added to the diagonal of A
C                         at the ith iteration
C
C
C***********************************************************************
      subroutine modchl(ndim,n,A,g,mcheps,tau1,tau2,P,E)
*
      integer n,ndim
      double precision A(ndim,n),g(n),mcheps,tau1,tau2
      integer P(n)
      double precision E(n)
*
C
C  j        - current iteration number
C  iming    - index of the row with the min. of the
C           neg. lower Gersch. bounds
C  imaxd    - index of the row with the maximum diag.
C           element
C  i,itemp,jpl,k  - temporary integer variables
C  delta    - amount to add to Ajj at the jth iteration
C  gamma    - the maximum diagonal element of the original
C           matrix A.
C  normj    - the 1 norm of A(colj), rows j+1 --> n.
C  ming     - the minimum of the neg. lower Gersch. bounds
C  maxd     - the maximum diagonal element
C  taugam - tau1 * gamma
C  phase1      - logical, true if in phase1, otherwise false
C  delta1,temp,jdmin,tdmin,tempjj - temporary double precision vars.
C
*
      integer j,iming,i,imaxd,itemp,jp1,k
      double precision delta,gamma
      double precision normj, ming,maxd
      double precision delta1,temp,jdmin,tdmin,taugam,tempjj
      logical phase1
      intrinsic abs, max, sqrt, min
*
      call init(n, ndim, A, phase1, delta, P, g, E,
     *         ming,tau1,gamma,taugam)
C
C     check for n=1
C
      if (n.eq.1) then
         delta = (tau2 * abs(A(1,1))) - A(1,1)
         if (delta .gt. 0) E(1) = delta
         if (A(1,1) .eq. 0) E(1) = tau2
         A(1,1)=sqrt(A(1,1)+E(1))
      endif
C
      do 200 j = 1, n-1
C
C        PHASE 1
C
         if ( phase1 ) then
C
C           Find index of maximum diagonal element A(i,i) where i>=j
C
            maxd = A(j,j)
            imaxd = j
            do 20 i = j+1, n
               if (maxd .lt. A(i,i)) then
                  maxd = A(i,i)
                  imaxd = i
               end if
 20         continue
*
C
C           Pivot to the top the row and column with the max diag
C
            if (imaxd .ne. j) then
C
C              Swap row j with row of max diag
C
               do 30 i = 1, j-1
                  temp = A(j,i)
                  A(j,i) = A(imaxd,i)
                  A(imaxd,i) = temp
 30            continue
C
C              Swap colj and row maxdiag between j and maxdiag
C
               do 35 i = j+1,imaxd-1
                  temp = A(i,j)
                  A(i,j) = A(imaxd,i)
                  A(imaxd,i) = temp
 35            continue
C
C              Swap column j with column of max diag
C
               do 40 i = imaxd+1, n
                  temp = A(i,j)
                  A(i,j) = A(i,imaxd)
                  A(i,imaxd) = temp
 40            continue
C
C              Swap diag elements
C
               temp = A(j,j)
               A(j,j) = A(imaxd,imaxd)
               A(imaxd,imaxd) = temp
C
C              Swap elements of the permutation vector
C
               itemp = P(j)
               P(j) = P(imaxd)
               P(imaxd) = itemp
*
            end if
*
*
C           Check to see whether the normal cholesky update for this
C           iteration would result in a positive diagonal,
C           and if not then switch to phase 2.
*
            jp1 = j+1
            tempjj=A(j,j)
*
            if (tempjj.gt.0) then
*
               jdmin=A(jp1,jp1)
               do 60 i = jp1, n
                  temp = A(i,j) * A(i,j) / tempjj
                  tdmin = A(i,i) - temp
                  jdmin = min(jdmin, tdmin)
 60            continue
*
               if (jdmin .lt. taugam) phase1 = .false.
*
            else
*
               phase1 = .false.
*
            end if
*
            if (phase1) then
C
C              Do the normal cholesky update if still in phase 1
C
               A(j,j) = sqrt(A(j,j))
               tempjj = A(j,j)
               do 70 i = jp1, n
                  A(i,j) = A(i,j) / tempjj
 70            continue
               do 80 i=jp1,n
                  temp=A(i,j)
                  do 75 k = jp1, i
                     A(i,k) = A(i,k) - (temp * A(k,j))
 75               continue
 80            continue
*
               if (j .eq. n-1) A(n,n)=sqrt(A(n,n))
*
            else
*
C
C              Calculate the negatives of the lower gerschgorin bounds
C
               call gersch(ndim,n,A,j,g)
*
            end if
*
         end if
*
*
C
C        PHASE 2
C
         if (.not. phase1) then
*
            if (j .ne. n-1) then
C
C              Find the minimum negative gershgorin bound
C
*
               iming=j
               ming = g(j)
               do 90 i = j+1,n
                  if (ming .gt. g(i)) then
                     ming = g(i)
                     iming = i
                  end if
 90            continue
*
C
C               Pivot to the top the row and column with the
C               minimum negative gerschgorin bound
C
                if (iming .ne. j) then
C
C                  Swap row j with row of min gersch bound
C
                   do 100 i = 1, j-1
                      temp = A(j,i)
                       A(j,i) = A(iming,i)
                       A(iming,i) = temp
 100               continue
C
C                  Swap colj with row iming from j to iming
C
                   do 105 i = j+1,iming-1
                      temp = A(i,j)
                      A(i,j) = A(iming,i)
                      A(iming,i) = temp
 105              continue
C
C                 Swap column j with column of min gersch bound
C
                  do 110 i = iming+1, n
                     temp = A(i,j)
                     A(i,j) = A(i,iming)
                     A(i,iming) = temp
 110              continue
C
C                 Swap diagonal elements
C
                  temp = A(j,j)
                  A(j,j) = A(iming,iming)
                  A(iming,iming) = temp
C
C                 Swap elements of the permutation vector
C
                  itemp = P(j)
                  P(j) = P(iming)
                  P(iming) = itemp
C
C                 Swap elements of the negative gerschgorin bounds vecto
C
                  temp = g(j)
                  g(j) = g(iming)
                  g(iming) = temp
*
               end if
C
C              Calculate delta and add to the diagonal.
C              delta=max{0,-A(j,j) + max{normj,taugam},delta_previous}
C              where normj=sum of |A(i,j)|,for i=1,n,
C              delta_previous is the delta computed at the previous iter
C              and taugam is tau1*gamma.
C
*
               normj = 0.0
               do 140 i = j+1, n
                  normj = normj + abs(A(i,j))
 140           continue
*
               temp = max(normj,taugam)
               delta1 = temp - A(j,j)
               temp = 0.0
               delta1 = max(temp, delta1)
               delta = max(delta1,delta)
               E(j) =  delta
               A(j,j) = A(j,j) + E(j)
C
C              Update the gerschgorin bound estimates
C              (note: g(i) is the negative of the
C               Gerschgorin lower bound.)
C
               if (A(j,j) .ne. normj) then
                  temp = (normj/A(j,j)) - 1.0
*
                  do 150 i = j+1, n
                     g(i) = g(i) + abs(A(i,j)) * temp
 150              continue
*
               end if
C
C              Do the cholesky update
C
               A(j,j) = sqrt(A(j,j))
               tempjj = A(j,j)
               do 160 i = j+1, n
                  A(i,j) = A(i,j) / tempjj
 160           continue
               do 180 i = j+1, n
                  temp = A(i,j)
                  do 170 k = j+1, i
                     A(i,k) = A(i,k) - (temp * A(k,j))
 170              continue
 180           continue
*
            else
*
               call fin2x2(ndim, n, A, E, j, tau2, delta,gamma)
*
            end if
*
         end if
*
 200   continue
*
      return
      end
C***********************************************************************
C       subroutine name : init
C
C       purpose : set up for start of cholesky factorization
C
C       input : n, ndim, A, tau1
C
C       output : phase1    - boolean value set to true if in phase one,
C             otherwise false.
C      delta     - amount to add to Ajj at iteration j
C      P,g,E - described above in modchl
C      ming      - the minimum negative gerschgorin bound
C      gamma     - the maximum diagonal element of A
C      taugam  - tau1 * gamma
C
C***********************************************************************
      subroutine init(n,ndim,A,phase1,delta,P,g,E,ming,
     *                tau1,gamma,taugam)
*
      integer n,ndim
      double precision A(ndim,n)
      logical phase1
      double precision delta,g(n),E(n)
      integer P(n)
      double precision ming,tau1,gamma,taugam
      intrinsic abs, max
*
*
      phase1 = .true.
      delta = 0.0
      ming = 0.0
      do 10 i=1,n
         P(i)=i
         g(i)= 0.0
         E(i) = 0.0
 10   continue
*
C
C     Find the maximum magnitude of the diagonal elements.
C     If any diagonal element is negative, then phase1 is false.
C
      gamma = 0.0
      do 20 i=1,n
         gamma=max(gamma,abs(A(i,i)))
         if (A(i,i) .lt. 0.0) phase1 = .false.
 20   continue
*
      taugam = tau1 * gamma
*
C
C     If not in phase1, then calculate the initial gerschgorin bounds
C     needed for the start of phase2.
C
      if ( .not.phase1) call gersch(ndim,n,A,1,g)
*
      return
      end
C***********************************************************************
C
C       subroutine name : gersch
C
C       purpose : Calculate the negative of the gerschgorin bounds
C                 called once at the start of phase II.
C
C       input   : ndim, n, A, j
C
C       output  : g - an n vector containing the negatives of the
C           Gerschgorin bounds.
C
C***********************************************************************
      subroutine gersch(ndim, n, A, j, g)
*
      integer ndim, n, j
      double precision A(ndim,n), g(n)
*
      integer i, k
      double precision offrow
      intrinsic abs
*
      do 30 i = j, n
         offrow = 0.0
         do 10 k = j, i-1
            offrow = offrow + abs(A(i,k))
 10      continue
         do 20 k = i+1, n
            offrow = offrow + abs(A(k,i))
 20      continue
            g(i) = offrow - A(i,i)
 30   continue
*
      return
      end
C***********************************************************************
C
C  subroutine name : fin2x2
C
C  purpose : Handles final 2X2 submatrix in Phase II.
C            Finds eigenvalues of final 2 by 2 submatrix,
C            calculates the amount to add to the diagonal,
C            adds to the final 2 diagonal elements,
C            and does the final update.
C
C  input : ndim, n, A, E, j, tau2,
C          delta - amount added to the diagonal in the
C                  previous iteration
C
C  output : A - matrix with complete L factor in the lower triangle,
C           E - n*1 vector containing the amount added to the diagonal
C               at each iteration,
C           delta - amount added to diagonal elements n-1 and n.
C
C***********************************************************************
      subroutine fin2x2(ndim, n, A, E, j, tau2, delta,gamma)
*
      integer ndim, n, j
      double precision A(ndim,n), E(n), tau2, delta,gamma
*
      double precision t1, t2, t3,lmbd1,lmbd2,lmbdhi,lmbdlo
      double precision delta1, temp
      intrinsic sqrt, max, min
*
C
C     Find eigenvalues of final 2 by 2 submatrix
C
      t1 = A(n-1,n-1) + A(n,n)
      t2 = A(n-1,n-1) - A(n,n)
      t3 = sqrt(t2*t2 + 4.0*A(n,n-1)*A(n,n-1))
      lmbd1 = (t1 - t3)/2.
      lmbd2 = (t1 + t3)/2.
      lmbdhi = max(lmbd1,lmbd2)
      lmbdlo = min(lmbd1,lmbd2)
C
C     Find delta such that:
C     1.  the l2 condition number of the final
C     2X2 submatrix + delta*I <= tau2
C     2. delta >= previous delta,
C     3. lmbdlo + delta >= tau2 * gamma,
C     where lmbdlo is the smallest eigenvalue of the final
C     2X2 submatrix
C
*
      delta1=(lmbdhi-lmbdlo)/(1.0-tau2)
      delta1= max(delta1,gamma)
      delta1= tau2 * delta1 - lmbdlo
      temp = 0.0
      delta = max(delta, temp)
      delta = max(delta, delta1)
*
      if (delta .gt. 0.0) then
         A(n-1,n-1) = A(n-1,n-1) + delta
         A(n,n) = A(n,n) + delta
         E(n-1) = delta
         E(n) = delta
      end if
C
C     Final update
C
      A(n-1,n-1) = sqrt(A(n-1,n-1))
      A(n,n-1) = A(n,n-1)/A(n-1,n-1)
      A(n,n) = A(n,n) - (A(n,n-1)**2)
      A(n,n) = sqrt(A(n,n))
*
      return
      end
C**********************************************************************
C
C     subroutine name : solve
C
C     purpose :  solves (LLtranspose)P(x)=P(b), where L is stored in
C                the lower triangle of A, P is the record of the
C                permutations  performed in forming L,b is the rhs vecto
C                and x is the result.
C                L is the result of the modified cholesky factorization
C                which computes Ptranspose(A+E)P=LLtranspose.
C
C  input:   ndim  - largest dimension of matrix that will be used
C
C           n     - dimension of matrix
C
C           A     - n*n array (only lower triangle portion,
C                   including the diagonal, is used).
C
C           P     - n*1 integer vector that contains a record
C                   of permutations performed in forming L.
C                   i.e. each Pi was initialized to i, and if
C                   row and columns i & j were interchanged when
C                   computing L, the values of Pi and Pj were swapped.
C
C           b     - n*1 double precision vector which is the
C                   right hand side of the system to be solved.
C
C           y,z   - n*1 double precision  work vectors.
C
C  output:  x     - n*1 double precision result vector
C
C
C**********************************************************************
*
      subroutine solve(ndim,n,A,P,x,b,y,z)
      integer n,ndim
      double precision A(ndim,n)
      double precision x(n),b(n)
      integer P(n)
      double precision y(n),z(n)
*
      integer i,j
      double precision sum
C
C     Solve Ly=Pb
C
      y(1) = b(P(1))/A(1,1)
      do 20 i=2,n
         sum=0.0
         do 10 j=1,i-1
            sum=sum + (A(i,j)*y(j))
 10      continue
         y(i) = (b(P(i)) - sum) / A(i,i)
 20   continue
C
C     Solve Ltranspose z = y
C
      z(n) = y(n)/A(n,n)
      do 40 i=n-1,1,-1
         sum=0.0
         do 30 j=i+1,n
            sum = sum + (A(j,i) * z(j))
 30      continue
         z(i) = (y(i) - sum) / A(i,i)
 40   continue
C
C     x = Ptranspose z
C
      do 50 i=1,n
         x(P(i))=z(i)
 50   continue
*
      return
      end
*