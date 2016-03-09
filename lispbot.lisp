(eval-when (:compile-toplevel :load-toplevel :execute)
  (declaim (optimize (debug 3))))
(eval-when (:compile-toplevel :load-toplevel :execute)
  (ql:quickload :cl-irc))
(eval-when (:compile-toplevel :load-toplevel :execute)
  (ql:quickload :cl+ssl))
(eval-when (:compile-toplevel :load-toplevel :execute)
  (ql:quickload :split-sequence))

(defparameter *connection* nil)
(defparameter *masters* '("fouric" "Synt4x" "nightfly"))

(defun part ()
  (when *connection*
    (irc:quit *connection*)
    (setf *connection* nil)))

(defun strip-irc-hats (string)
  (if (or (position #\+ string) (position #\@ string))
      (subseq string 1 (length string))
      string))

(defun test ()
  (let (names
	name-requester)
    (flet ((message-received-hook (message)
	     (let* ((arguments (irc:arguments message))
		    ;(channel (first arguments))
		    (contents (second arguments))
		    (sender (irc:source message)))
	       (when (and (position #\: contents) (< (position #\: contents) (or (position #\Space contents) (length contents))))
		 (setf (aref contents (position #\: contents)) #\Space))
	       (let ((command-list (handler-case (with-input-from-string (s contents) (read s))
				     (end-of-file ()
				       (print "error!")
				       nil)
				     (sb-int:simple-reader-error ()
				       (print "other error!")
				       nil))))
		 (when (and command-list (eq (type-of command-list) 'cons))
		   (print command-list)
		   (when (and (member sender *masters* :test #'string=) (eq 'lispbot (first command-list)))
		     (let ((command (second command-list)))
		       (case command
			 (quit
			  (part))
			 (names
			  (irc:names *connection* "#bots")
			  (setf name-requester sender))
			 (in-channel-p
			  (irc:privmsg *connection* "#bots" (format nil (if (member (string-downcase (string (third command-list))) (mapcar #'string-downcase names) :test #'string=)
									    "User ~A is in the current channel."
									    "User ~A is not in the current channel.") (string (third command-list)))))
			 (source
			  (irc:privmsg *connection* "#bots" (format nil "~A: https://github.com/fouric/lispbot" sender)))
			 (otherwise
			  (irc:privmsg *connection* "#bots" (format nil "~A: Command not recognized: ~A" sender command)))))))))
	     t)
	   (names-hook (message)
	     (setf names (mapcar #'strip-irc-hats (split-sequence:split-sequence #\Space (first (last (irc:arguments message))))))
	     (print names)
	     (when name-requester
	       (irc:privmsg *connection* name-requester (format nil "~A" names))
	       (setf name-requester nil))))
      (unless *connection*
	(setf *connection* (irc:connect :nickname "lispbot" :server "irc.cat.pdx.edu" :port 6697 :connection-security :ssl)))
      (irc:join *connection* "#bots" :password (getf (with-open-file (in "auth.dat") (with-standard-io-syntax (read in))) :key))
      (irc:add-hook *connection* 'irc:irc-privmsg-message #'message-received-hook)
      (irc:add-hook *connection* 'irc:irc-rpl_namreply-message #'names-hook)
      (irc:read-message-loop *connection*)
      )))
