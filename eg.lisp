;; 
;; You can evaluate this file with:
;;    ./eval-lisp eg.lisp
;;


(defun sum (a b &optional c)
  (write a b c)
  (+ a b))

(setq a 100)
(setq b (sum 4 5))
(write (print (list a b)))

(write (ord "a"))
(write (chr ?a))

(write (localtime (- (time) (* 24 60 60))))
