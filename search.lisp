;; sbcl --script search.lisp (Exa and Brave Search APIs)
#-quicklisp (load "~/quicklisp/setup.lisp")
(ql:quickload :com.inuoe.jzon :silent t)

(defun curl-json (&rest args)
  (com.inuoe.jzon:parse
   (uiop:run-program (list* "curl" "-s" args) :output :string)))

(defun results (items text-key)
  "List of (title url text) for each hit."
  (map 'list
       (lambda (h)
         (list (gethash "title" h)
               (gethash "url" h)
               (gethash text-key h)))
       items))

(defun esearch (query &optional (n 5))
  (results
   (gethash "results"
            (curl-json
             "https://api.exa.ai/search"
             "-H" (format nil "x-api-key: ~a"
                          (uiop:getenv "EXA_SEARCH_API_KEY"))
             "-H" "Content-Type: application/json"
             "-d" (format nil
                   (concatenate
                    'string
                    "{\"query\":~a,\"numResults\":~d,"
                    "\"contents\":{\"text\":{\"maxCharacters\":300}}}")
                   (com.inuoe.jzon:stringify query) n)))
   "text"))

(defun bsearch (query &optional (n 5))
  (results
   (gethash
    "results"
    (gethash
     "web"
     (curl-json
      "-G" "https://api.search.brave.com/res/v1/web/search"
      "-H" (format nil "X-Subscription-Token: ~a"
                   (uiop:getenv "BRAVE_SEARCH_API_KEY"))
      "-H" "Accept: application/json"
      "--data-urlencode" (format nil "q=~a" query)
      "--data-urlencode" (format nil "count=~d" n))))
   "description"))

(print (esearch "Common Lisp SPARQL client" 3))
(print (bsearch "Sedona Arizona hiking" 3))
