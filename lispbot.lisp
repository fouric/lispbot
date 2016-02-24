(eval-when (:compile-toplevel :load-toplevel :execute)
  (declaim (optimize (debug 3))))
(eval-when (:compile-toplevel :load-toplevel :execute)
  (ql:quickload :cl-irc))

(defparameter *connection* nil)

(defun part ()
  (when *connection*
    (irc:quit *connection*)
    (setf *connection* nil)))

(defun test ()
  (flet ((message-received-hook (message)
	   (let* ((arguments (irc:arguments message))
		  (channel (first arguments))
		  (contents (second arguments))
		  (sender (irc:source message)))
	     (format t "message received: ~A~%" (irc:arguments message))
	     (irc:privmsg *connection* sender (format nil "you said: ~A" contents))
	     )))
    (unless *connection*
      (setf *connection* (irc:connect :nickname "lispbot" :server "irc.cat.pdx.edu")))
    (irc:join *connection* "#bots")
    (irc:add-hook *connection* 'irc:irc-privmsg-message #'message-received-hook)
    (irc:read-message-loop *connection*)))
