;;;; symbolic-math.lisp: symbolic polynomial calculus.
;;;; Polynomials are alists ((exponent . coefficient) ...):
;;;; descending exponents, like terms combined, zeros dropped.
;;;; 3x^2 - x + 5 = ((2 . 3) (1 . -1) (0 . 5))

(defun normalize (terms)
  (let ((h (make-hash-table)))
    (loop for (e . c) in terms do (incf (gethash e h 0) c))
    (sort (loop for e being the hash-keys of h using (hash-value c)
                unless (zerop c) collect (cons e c))
          #'> :key #'car)))

(defun poly (&rest coefs)               ; (poly 3 -1 5) => 3x^2 - x + 5
  (normalize
   (loop for c in (reverse coefs) for e from 0 collect (cons e c))))

;;; Arithmetic & evaluation
(defun p+ (&rest ps) (normalize (apply #'append ps)))
(defun scale (p k)
  (normalize (loop for (e . c) in p collect (cons e (* k c)))))
(defun p- (p q)      (p+ p (scale q -1)))
(defun degree (p)    (if p (caar p) -1))
(defun evaluate (p x) (loop for (e . c) in p sum (* c (expt x e))))

;;; Calculus: power rule, reverse power rule, fundamental theorem
(defun deriv (p &optional (n 1))
  (if (zerop n) p
      (deriv
       (loop for (e . c) in p
             unless (zerop e)
             collect (cons (1- e) (* e c)))
       (1- n))))

(defun integ (p &optional (n 1))
  (if (zerop n) p
      (integ
       (loop for (e . c) in p
             collect (cons (1+ e) (/ c (1+ e))))
       (1- n))))

(defun bound (b)
  (case b (:pi pi) (:e (exp 1d0)) (t (float b 1d0))))

(defun definite (p a b)
  (let ((f (integ p)))
    (- (evaluate f (bound b)) (evaluate f (bound a)))))

(defun critical-point-p (p x &optional (tol 1d-9))
  (< (abs (evaluate (deriv p) x)) tol))

;;; Display
(defun ->string (p &optional (v 'x))
  (if (null p) "0"
      (format nil "~{~a~^ + ~}"
              (loop for (e . c) in p
                    collect (format nil "~a~@[~(~a~)~]~@[^~a~]"
                                    c (and (> e 0) v)
                                    (and (> e 1) e))))))

(defun integral->string (p &optional a b (v 'x))
  (flet ((show (b) (case b (:pi "π") (:e "e") (t b))))
    (format nil "∫~@[[~{~a~^,~}]~](~a) d~(~a~)"
            (and a (list (show a) (show b)))
            (->string p v)
            v)))

;;; Examples
(let ((p (poly 3 -1 5))                 ; 3x^2 - x + 5
      (q (poly 1 2)))                   ; x + 2
  (format t "p          : ~a~%" (->string p))
  (format t "p + q      : ~a~%" (->string (p+ p q)))
  (format t "p - q      : ~a~%" (->string (p- p q)))
  (format t "2p         : ~a~%" (->string (scale p 2)))
  (format t "degree, p(2): ~a, ~a~%" (degree p) (evaluate p 2))
  (format t "p', p'', p''': ~a | ~a | ~a~%"
          (->string (deriv p))
          (->string (deriv p 2))
          (->string (deriv p 3)))
  (format t "∫p, ∫∫p    : ~a | ~a~%"
          (->string (integ p))
          (->string (integ p 2)))
  (format t "~a = ~a~%" (integral->string p 0 1) (definite p 0 1))
  (format t "~a = ~,4f~%" (integral->string p 0 :pi) (definite p 0 :pi))
  (format t "x=1/6 critical? ~a  x=0? ~a~%"
          (critical-point-p p 1/6)
          (critical-point-p p 0)))
