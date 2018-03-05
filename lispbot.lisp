(proclaim '(optimize (speed 0) (debug 3)))

(require 'cl-irc)
(require 'cl+ssl)
(require 'split-sequence)
(require 'trivial-shell)
(require 'swank)
(require 'alexandria)

(defpackage :lispbot (:use :common-lisp :irc :cl+ssl :split-sequence :alexandria)
            (:export #:run #:part))
(in-package :lispbot)

(defparameter *connection* nil)
(defparameter *nick* nil)

(defun part-channel ()
  (when *connection*
    (irc:quit *connection*)
    (setf *connection* nil)))

(defparameter *gonna-quit* nil)

;; a "hook" is some sort of function that we run in response to an event
;; this one happens to take one parameter that is filled in with a message by cl-irc
(defun message-received-hook (message)
  (let* ((arguments (irc:arguments message))
         (contents (second arguments))
         (channel (first arguments))
         (sender (irc:source message))
         (split (split-sequence:split-sequence #\Space contents))
         (head (first split))
         (body (rest split)))
    (format t "The sender of the message is: ~a~%" sender)
    (when (search *nick* head)
      (alexandria:switch ((first body) :test 'string=)
        ("foo"
         (irc:privmsg *connection* channel (format nil "foo to YOU, ~A!" sender)))
        ("drop"
         (if *gonna-quit*
             (part-channel)
             (progn
               (setf *gonna-quit* t)
               (irc:privmsg *connection* channel (format nil "NOT YET")))))
        ("source"
         (irc:privmsg *connection* channel "https://github.com/fouric/lispbot"))
        ;; this line will cause the bot to reply to whoever said "hello" to it
        ("hello"
         (let ((string-to-send (format nil "Hello, ~A!" sender)))
           ;; make the string lowercase so that we don't have to use lowercase ourselves
           (irc:privmsg *connection* sender string-to-send)))
        (t
         (irc:privmsg *connection* channel (format nil "command ~s unimplemented")))))))

(defmacro continuable (&body body)
  `(restart-case
       (progn ,@body)
     (continue () :report "Continue")))

(defun update-swank ()
  (continuable
    (let ((connection (or swank::*emacs-connection* (swank::default-connection))))
      (when connection
        (swank::handle-requests connection t)))))

(let ((random-state (make-random-state t)))
  (random 100000 random-state))

(defun run (&key (channel "#lisp") bot-nick (auth-required nil))
  (setf *nick* (or bot-nick (format nil "lispbot~A"
                                    (let ((random-state (make-random-state t)))
                                      (random 10000 random-state)))))
  (unless *connection*
    (setf *connection* (irc:connect :nickname *nick*
                                    :server "irc.cat.pdx.edu"
                                    :port 6697
                                    :connection-security :ssl)))
  (if auth-required
      (let ((auth-file (open "auth.dat")))
        (let ((auth-data (read auth-file)))
          (irc:join *connection* channel :password (getf auth-data :key)))
        (close auth-file))
      (irc:join *connection* channel))
  (irc:add-hook *connection* 'irc:irc-privmsg-message (lambda (m) (update-swank) (message-received-hook m)))
  (irc:read-message-loop *connection*))
