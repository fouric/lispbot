(eval-when (:compile-toplevel :load-toplevel :execute) (declaim (optimize (debug 3))))

(eval-when (:compile-toplevel :load-toplevel :execute) (ql:quickload :cl-irc))
(eval-when (:compile-toplevel :load-toplevel :execute) (ql:quickload :cl+ssl))
(eval-when (:compile-toplevel :load-toplevel :execute) (ql:quickload :split-sequence))
(eval-when (:compile-toplevel :load-toplevel :execute) (ql:quickload :trivial-shell))

(defpackage :lispbot (:use :common-lisp :irc :cl+ssl :split-sequence)
	    (:export :run :part))
(in-package :lispbot)

(defparameter *connection* nil)

(defmacro fn-case (keyform test &body clauses)
  (let ((kf (gensym))
	(tst (gensym)))
    `(let ((,kf ,keyform)
	   (,tst ,test))
       (cond
	 ,@ (mapcar (lambda (clause)
		      (if (eq (car clause) t)
			  `(t
			    ,@ (cdr clause))
			  (let ((key (car clause))
				(code (cdr clause)))
			    `((funcall ,tst ,kf ,key)
			      ,@code)))) clauses)))))
(defun part ()
  (when *connection*
    (irc:quit *connection*)
    (setf *connection* nil)))

(defun run ()
  (flet ((message-received-hook (message)
	   (let* ((arguments (irc:arguments message))
		  ;;(channel (first arguments))
		  (contents (second arguments))
		  ;;(sender (irc:source message))
		  (split (split-sequence:split-sequence #\Space contents))
		  (head (first split))
		  (body (rest split)))
	     (print (cons head body))
	     (when (search "dbot" head))
	     (fn-case (first body) #'string=
	       ("drop"
		(part))
	       ("source"
		(irc:privmsg *connection* "#bots" "https://github.com/fouric/lispbot"))))))
    (unless *connection*
      (setf *connection* (irc:connect :nickname "lispbot" :server "irc.cat.pdx.edu" :port 6697 :connection-security :ssl)))
    (irc:join *connection* "#bots" :password (getf (with-open-file (in "auth.dat") (with-standard-io-syntax (read in))) :key))
    ;;(irc:join *connection* "#robots" :password (getf (with-open-file (in "auth.dat") (with-standard-io-syntax (read in))) :key))
    (irc:add-hook *connection* 'irc:irc-privmsg-message #'message-received-hook)
    (irc:read-message-loop *connection*)))
