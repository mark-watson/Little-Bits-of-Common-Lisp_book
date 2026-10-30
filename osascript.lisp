;;;; osascript.lisp -- tiny macOS automation via osascript.   (load "osascript")
;;;; Needs Automation permission for your terminal (System Settings > Privacy & Security);
;;;; READ-RECENT-IMESSAGES also needs Full Disk Access, SAFARI-LOGIN needs
;;;; Safari > Develop > Allow JavaScript from Apple Events.  Keep credentials out of this file.
(require :asdf)

(defun osascript (script)               ; returns trimmed stdout, or signals osascript's own error
  (multiple-value-bind (out err code)
      (uiop:run-program (list "osascript" "-e" script)
                        :output :string :error-output :string :ignore-error-status t)
    (if (zerop code) (string-trim '(#\Space #\Newline) out) (error "osascript: ~a" err))))

;;; ~S quotes Lisp strings so they are valid AppleScript (and JavaScript) string literals.
(defun mail-unread-count ()
  (parse-integer (osascript "tell application \"Mail\" to return unread count of inbox")))

(defun get-todays-events ()
  (remove "" (uiop:split-string (osascript "tell application \"Calendar\"
  set t0 to current date
  set time of t0 to 0
  set out to {}
  repeat with c in calendars
    set out to out & (summary of every event of c whose start date >= t0 and start date < t0 + days)
  end repeat
  set AppleScript's text item delimiters to \"|\"
  return out as string
end tell") :separator "|") :test #'string=))

(defun send-imessage (phone message)
  (osascript (format nil "tell application \"Messages\" to send ~S to buddy ~S of (1st service whose service type = iMessage)"
                     message phone)))

(defun add-reminder (name)
  (osascript (format nil "tell application \"Reminders\" to return id of (make new reminder with properties {name:~S})" name)))

(defun read-recent-imessages (&optional (limit 5))   ; JSON string from chat.db
  (check-type limit (integer 1))
  (uiop:run-program (list "sqlite3" "-json" (namestring (merge-pathnames "Library/Messages/chat.db" (user-homedir-pathname)))
                          (format nil "SELECT m.is_from_me, h.id AS sender, m.text FROM message m LEFT JOIN handle h ON m.handle_id = h.ROWID WHERE m.text IS NOT NULL ORDER BY m.date DESC LIMIT ~d;" limit))
                    :output :string))

(defun safari-login (url user password &key (user-id "username") (password-id "password") (form-id "login-form") (timeout 30))
  (osascript (format nil "tell application \"Safari\"
  set d to make new document with properties {URL:~S}
  repeat ~d times
    delay 0.5
    if (do JavaScript \"document.readyState\" in d) is \"complete\" then return (do JavaScript ~S in d)
  end repeat
end tell
error \"Safari page did not load within ~d seconds\""
                     url (* 2 timeout)
                     (format nil "document.getElementById(~S).value = ~S; document.getElementById(~S).value = ~S; document.getElementById(~S).submit();"
                             user-id user password-id password form-id)
                     timeout)))

;;; Examples
;; (osascript "return 1 + 10")
;; (mail-unread-count)
;; (get-todays-events)
;; (add-reminder "Buy milk")
;; (send-imessage "+15551234567" "Hello from Lisp")
;; (read-recent-imessages 3)
;; (safari-login "https://leanpub.com/author/royalties/summary" (uiop:getenv "LEANPUB_USER") (uiop:getenv "LEANPUB_PASSWORD"))
