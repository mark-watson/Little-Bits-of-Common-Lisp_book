;; (load "load.lisp") then (help): loads definitions from every file,
;; skipping the example calls at the bottom of each file.
#-quicklisp (load "~/quicklisp/setup.lisp")

(let ((dir (directory-namestring
            (or *load-truename* *default-pathname-defaults*))))
  (dolist (f (directory (merge-pathnames "*.lisp" dir)))
    (unless (equal (pathname-name f) "load")
      (with-open-file (s f)
        (let ((*package* (find-package :cl-user)))
          (loop for form = (read s nil s) until (eq form s)
                when (and (consp form)
                          (member (car form)
                                  '(defun defstruct defvar defparameter
                                    defpackage in-package require load
                                    ql:quickload)))
                  do (eval form)))))))

(defparameter *help*
  '(("apple-system-model.lisp")
    ("(apple-fm \"what is 1 + 10?\")"
     "on-device Apple model via `fm`")
    ("gemini.lisp")
    ("(gemini \"hi\" [model])"
     "Google Gemini (GOOGLE_API_KEY)")
    ("ollama.lisp")
    ("(ollama \"hi\" [model])"
     "local Ollama model")
    ("sparql.lisp")
    ("(sparql endpoint \"SELECT ...\")"
     "SPARQL query -> rows of (var . value)")
    ("(dbpedia \"SELECT ...\")"
     "query DBpedia")
    ("(wikidata \"SELECT ...\")"
     "query Wikidata")
    ("lightpanda.lisp")
    ("(lightpanda url [\"markdown\"])"
     "JS-rendered page via Lightpanda")
    ("(links html)"
     "href strings in an HTML string")
    ("webscraping.lisp")
    ("(fetch url)"
     "fetch and parse a page (plump DOM)")
    ("(text node)"
     "plain text of a plump node")
    ("(clean string)"
     "trim spaces, collapse blank lines")
    ("(headers url)"
     "h1-h6 texts of a page")
    ("(page-text url)"
     "readable plain text of a page")
    ("search.lisp")
    ("(esearch \"query\" [n])"
     "Exa search -> (title url text)")
    ("(bsearch \"query\" [n])"
     "Brave search -> (title url text)")
    ("(curl-json &rest curl-args)"
     "run curl, parse JSON reply")
    ("(results items text-key)"
     "hits -> (title url text) lists")
    ("osascript.lisp")
    ("(osascript \"return 1 + 10\")"
     "run AppleScript, return stdout")
    ("(mail-unread-count)"
     "Mail inbox unread count")
    ("(get-todays-events)"
     "today's Calendar event titles")
    ("(add-reminder \"Buy milk\")"
     "add a Reminders item")
    ("(send-imessage \"+1555...\" \"Hi\")"
     "send an iMessage")
    ("(read-recent-imessages 3)"
     "recent iMessages as JSON")
    ("(safari-login url user password)"
     "fill and submit a Safari login form")
    ("symbolic-math.lisp  (p = (poly 3 -1 5) is 3x^2 - x + 5)")
    ("(poly 3 -1 5)"
     "polynomial from coefficients")
    ("(normalize terms)"
     "combine like terms, sort")
    ("(p+ p q ...) (p- p q)"
     "add / subtract polynomials")
    ("(scale p 2)"
     "multiply by a constant")
    ("(degree p) (evaluate p 2)"
     "degree / value at x")
    ("(deriv p [n])"
     "nth derivative")
    ("(integ p [n])"
     "nth antiderivative (no +C)")
    ("(bound :pi)"
     "bound -> float (numbers, :pi, :e)")
    ("(definite p 0 1)"
     "definite integral from a to b")
    ("(critical-point-p p 1/6)"
     "is p'(x) = 0 ?")
    ("(->string p)"
     "p as text: 3x^2 + -1x + 5")
    ("(integral->string p 0 1)"
     "integral as text")
    ("bayes.lisp")
    ("(bayes-update dist evidence l-fn)"
     "Bayes update -> normalized posterior alist")
    ("(bayes-normalize dist)"
     "normalize alist probabilities to sum to 1.0")
    ("(map-hypothesis dist)"
     "maximum a posteriori (MAP) hypothesis pair")
    ("triple-store.lisp")
    ("(add-triple s p o)"
     "add (s p o) triple to store")
    ("(query-triples patterns [store])"
     "query graph via pattern match & relational join")
    ("autograd.lisp")
    ("(val number)"
     "wrap scalar in autograd computation node")
    ("(v+ a b) (v* a b) (v-relu a)"
     "autograd scalar math operations")
    ("(backward root)"
     "reverse-mode automatic differentiation backprop")
    ("bm25.lisp")
    ("(tokenize text)"
     "extract alphanumeric lowercase tokens")
    ("(bm25-search corpus query)"
     "Okapi BM25 ranked document retrieval")
    ("hopfield.lisp")
    ("(hopfield-train patterns size)"
     "Hebbian training -> 2D weight matrix")
    ("(hopfield-recall w input [steps])"
     "associative recall of corrupted pattern")
    ("(hopfield-energy w state)"
     "Lyapunov energy function")
    ("(show-pattern pat [width])"
     "render bipolar pattern as #/. grid")
    ("vector-store.lisp")
    ("(make-vector-store)"
     "create in-memory dense vector store")
    ("(store-add store id text vec)"
     "add labeled vector to store")
    ("(store-search store qvec [k])"
     "top-K nearest neighbors by cosine similarity")
    ("(v-dot a b)"
     "dot product of two vectors")
    ("(v-norm a)"
     "Euclidean norm of a vector")
    ("(v-cosine a b)"
     "cosine similarity between vectors")
    ("summarizer.lisp")
    ("(summarize text [n])"
     "extractive text summarization (top-N sentences)")
    ("(words text) (split-sentences text)"
     "NLP tokenization and sentence segmentation")
    ("load.lisp")
    ("(help [filter])"
     "print this list (optionally filtered by string)")))

(defun help (&optional filter)
  (let ((filter (and filter (string filter))))
    (dolist (h *help*)
      (if (cdr h)
          (when (or (null filter)
                    (search filter (first h) :test #'char-equal)
                    (and (second h)
                         (search filter (second h) :test #'char-equal)))
            (format t "  ~34a ; ~a~%" (first h) (second h)))
          (when (null filter)
            (format t "~a~%" (first h))))))
  (values))
