(eval-when (:compile-toplevel :load-toplevel :execute)
  (declaim (optimize (debug 3))))
(eval-when (:compile-toplevel :load-toplevel :execute)
  (ql:quickload :cl-irc))
(eval-when (:compile-toplevel :load-toplevel :execute)
  (ql:quickload :cl+ssl))

(defparameter *connection* nil)

(defun part ()
  (when *connection*
    (irc:quit *connection*)
    (setf *connection* nil)))

(defun test ()
  (let (names)
    (flet ((message-received-hook (message)
	     (let* ((arguments (irc:arguments message))
		    (channel (first arguments))
		    (contents (second arguments))
		    (sender (irc:source message)))
	       (if names
		   (progn
		     (print (first (last (irc:arguments names))))
		     (setf names nil)
		     (part))
		 (irc:names *connection* "#bots"))))
	   (names-hook (message)
	     (setf names message)))
      (unless *connection*
	(setf *connection* (irc:connect :nickname "lispbot" :server "irc.cat.pdx.edu" :port 6697 :connection-security :ssl)))
      (irc:join *connection* "#bots" :password (getf (with-open-file (in "auth.dat") (with-standard-io-syntax (read in))) :key))
      (irc:add-hook *connection* 'irc:irc-privmsg-message #'message-received-hook)
      (irc:add-hook *connection* 'irc:irc-rpl_namreply-message #'names-hook)
      (irc:read-message-loop *connection*)
      )))
