# Little Bits of Common Lisp

*Seventeen tiny programs: LLMs, the web, macOS automation, classic AI, and symbolic math, each in a single file*

**by Mark Watson**

# Preface

I have used Common Lisp professionally since 1982. The language remains fast, flexible, and stable for artificial intelligence, data processing, and symbolic computing.

This book collects small, complete programs. Each chapter holds one working example in a single file. Read the chapters in any order: pick the topics that interest you and run the code.

For deeper coverage and larger projects, see my book *Loving Common Lisp* at <https://leanpub.com/lovinglisp>. My other books, software, and articles are at <https://markwatson.com>.

I thank my wife Carol Watson for her support and editorial help.

# Introduction

This book contains small, complete Common Lisp programs. Each chapter covers one self-contained `.lisp` file (most well under 100 lines) that you can read in a few minutes and run with `sbcl --script`. Nothing is left out: each chapter lists the whole program, explains how it works, shows a run, and suggests ways to use and extend it.

The examples are practical. They call large language models (Apple's on-device model, Google Gemini, local Ollama models), query web search APIs and SPARQL knowledge graphs, scrape and render web pages, automate macOS apps, and implement classic algorithms from scratch: Bayesian inference, BM25 document ranking, a Hopfield network, a triple store, a vector store, an extractive summarizer, symbolic polynomial calculus, and reverse-mode automatic differentiation.

A note on style: the network examples run `curl` (via `uiop:run-program`) instead of loading an HTTP client library. This keeps dependencies few and makes each program easy to copy into your own projects.

## What you need

- SBCL: every program except the AppleScript library runs with `sbcl --script filename.lisp`.
- Quicklisp: the Gemini, Ollama, search, SPARQL, and web-scraping examples need it.
- curl: every network example uses it as the HTTP client.
- API keys in environment variables: `GOOGLE_API_KEY` for Gemini, `EXA_SEARCH_API_KEY` and `BRAVE_SEARCH_API_KEY` for the web search chapter.
- Ollama: a local Ollama server for the Ollama chapter.
- Lightpanda: the Lightpanda headless browser binary.
- macOS: for the AppleScript automation and Apple Foundation Model chapters.

Each program starts with a comment that shows how to run it. The chapters are independent, so read them in any order. To load every definition into one REPL session and experiment, see the last chapter on `load.lisp`. I load `load.lisp` from my SBCL `.sbclrc` file, so every function in this book, plus the `help` function that lists them, is ready in all my REPL sessions.

## Which chapters run as-is

| Chapter | Needs beyond SBCL | Output in this book |
|---|---|---|
| Apple Foundation Models | macOS + Apple Intelligence + `fm` | Real transcript |
| Gemini | Quicklisp + `GOOGLE_API_KEY` | Real transcript |
| Ollama | Local `ollama serve` + pulled model | Real transcript |
| Web search (Exa, Brave) | Quicklisp + two API keys | Real transcript, abridged |
| SPARQL | Quicklisp | Real transcript |
| Lightpanda | `lightpanda` binary | Real transcript, abridged |
| Web scraping | Quicklisp | Real transcript, abridged |
| AppleScript automation | macOS (+ permissions per function) | One real line; rest are live-state calls |
| Bayes, BM25, Hopfield, triple store, vector store, summarizer, symbolic math, autograd | Nothing | Real transcript, verbatim |

All example files are in the book's GitHub repository: <https://github.com/mark-watson/Little-Bits-of-Common-Lisp_book>.

# On-device AI with Apple foundation models

File: `apple-system-model.lisp`

Recent macOS versions ship with Apple's on-device foundation model, which scripts reach through the `fm` command-line tool. This nine-line program is the shortest LLM client in the book: no API key, no network, no bill.

## The code

```lisp
;; sbcl --script apple-system-model.lisp (macOS Apple Foundation Model)
(require :asdf)

(defun apple-fm (prompt)
  (string-trim '(#\Space #\Newline #\Return)
               (uiop:run-program
                (list "fm" "respond" "--no-stream" prompt)
                :output :string)))

(print (apple-fm "what is 1 + 10?"))
```

## How it works

- `(require :asdf)` loads UIOP. This book uses `uiop:run-program` throughout to run external commands and capture their output.
- `apple-fm` runs `fm respond --no-stream <prompt>` and captures standard output as a string with `:output :string`. The `--no-stream` flag makes `fm` print the whole reply at once instead of streaming tokens.
- `string-trim` removes the whitespace that `fm` adds around the reply.

## Running it

You need macOS with Apple Intelligence turned on and the `fm` license accepted (`sudo fm license`). Then:

```bash
$ sbcl --script apple-system-model.lisp
```

The program prints the model's reply as a Lisp string. Actual output (the wording varies between runs):

```text
"11"
```

## Using it

The model runs on your Mac, so use it for prompts that should not leave the machine: summarizing private notes, classifying local documents, or adding small language tasks to Lisp scripts. The trade-offs: the model is small and weaker than hosted models, and this interface gives no control over temperature or system prompts. For harder tasks, see the Gemini and Ollama chapters that follow.

# Calling Google Gemini

File: `gemini.lisp`

This program calls Google's Gemini API and parses the JSON reply in about thirty lines, including error handling and the demo call.

## The code

```lisp
;; sbcl --script gemini.lisp   (needs Quicklisp + GOOGLE_API_KEY)
#-quicklisp (load "~/quicklisp/setup.lisp")
(ql:quickload :com.inuoe.jzon :silent t)

(defun gemini (prompt &optional (model "gemini-3.5-flash-lite"))
  (let* ((base
          "https://generativelanguage.googleapis.com/v1beta/models/")
         (url (format nil "~a~a:generateContent" base model))
         (key (or (uiop:getenv "GOOGLE_API_KEY")
                  (error "GOOGLE_API_KEY is not set")))
         (body (format nil
                       "{\"contents\":[{\"parts\":[{\"text\":~a}]}]}"
                       (com.inuoe.jzon:stringify prompt)))
         (j (com.inuoe.jzon:parse
             (uiop:run-program
              (list "curl" "-s" url
                    "-H" "Content-Type: application/json"
                    "-H" (format nil "x-goog-api-key: ~a" key)
                    "-d" body)
              :output :string)))
         (candidates (gethash "candidates" j)))
    (unless candidates
      (error "Gemini: ~a"
             (let ((e (gethash "error" j)))
               (if e (gethash "message" e) "no candidates in reply"))))
    (gethash "text"
             (aref (gethash "parts"
                            (gethash "content" (aref candidates 0)))
                   0))))

(print (gemini "what is 1 + 10?"))
```

## How it works

- `#-quicklisp` reads as "if Quicklisp is not loaded": run as a script, the file loads `~/quicklisp/setup.lisp` first. With this idiom the same file works both as a script and in a REPL that already has Quicklisp.
- `com.inuoe.jzon` is a fast JSON library. `jzon:parse` turns JSON into hash tables and vectors; `jzon:stringify` turns a Lisp string into an escaped JSON string literal.
- `format` builds the request body, and `jzon:stringify` escapes the prompt. Pasting user text into JSON by hand breaks on the first quote or backslash in the prompt; the one `stringify` call prevents that.
- `curl -s` POSTs to the `generateContent` endpoint with the API key in the `x-goog-api-key` header. `uiop:getenv` reads the key from the environment, and the `(or ... (error ...))` idiom fails at once with a clear message when the key is missing, instead of sending the header `x-goog-api-key: NIL`.
- A successful reply nests the text at `candidates[0].content.parts[0].text`. The final expression reaches it with `gethash` and `aref`.
- A failed request (bad key, unknown model, rate limit) returns JSON with an `error` object instead of `candidates`. The `unless` check turns that into a Lisp error that carries Google's own message, for example `Gemini: models/no-such-model is not found for API version v1beta...`.

## Running it

```bash
$ export GOOGLE_API_KEY=...   # from https://aistudio.google.com
$ sbcl --script gemini.lisp
```

Actual output (the wording varies between runs, as with any language model):

```text
"1 + 10 = 11"
```

## Using it

Pass a second argument to switch models: `(gemini "summarize this file" "gemini-3.5-flash")`. The function works well with later examples in the book: summarize the output of the web-scraping chapter, or answer questions about documents ranked by the BM25 chapter. Failures signal ordinary Lisp errors, so you can wrap calls in `handler-case` to retry after a rate limit or fall back to the local Ollama model in the next chapter.

# Local LLMs with Ollama

File: `ollama.lisp`

This chapter uses the same pattern as the Gemini chapter, but calls a model on your own machine through Ollama's HTTP API.

## The code

```lisp
;; sbcl --script ollama.lisp   (needs Quicklisp + local Ollama)
#-quicklisp (load "~/quicklisp/setup.lisp")
(ql:quickload :com.inuoe.jzon :silent t)

(defun ollama (prompt &optional (model "qwen3.5:4b"))
  (let* ((fmt
          (concatenate
           'string
           "{\"model\":~a,\"prompt\":~a,"
           "\"stream\":false,\"think\":false}"))
         (body (format nil fmt
                       (com.inuoe.jzon:stringify model)
                       (com.inuoe.jzon:stringify prompt)))
         (j (com.inuoe.jzon:parse
             (uiop:run-program
              (list "curl" "-s"
                    "http://localhost:11434/api/generate"
                    "-d" body)
              :output :string))))
    (or (gethash "response" j)
        (error "Ollama: ~a" (gethash "error" j)))))

(print (ollama "what is 1 + 10?"))
```

## How it works

- Ollama serves a local HTTP API on port 11434. The `/api/generate` endpoint takes a model name and a prompt.
- `"stream":false` asks for the whole reply in one JSON document instead of a stream of token fragments, so a single `jzon:parse` handles it.
- `"think":false` turns off the reasoning trace on models that have one (like the Qwen 3 family), so the `response` field holds just the answer.
- The reply's `response` key holds the generated text, which the function returns. When something fails (most often a model you have not pulled), the reply has an `error` key instead, and the final `or` signals it as a Lisp error such as `Ollama: model 'llama9' not found`. If the server is down, `curl` exits with a non-zero status and `uiop:run-program` signals an error itself.

## Running it

Install Ollama, pull the model (`ollama pull qwen3.5:4b`), start the server, then:

```bash
$ sbcl --script ollama.lisp
```

Actual output (the wording varies between runs):

```text
"The result of $1 + 10$ is **11**."
```

## Using it

Local models are private, cost nothing per call, and work offline, which suits batch jobs over local documents (pair this with the summarizer or vector-store chapters). Change the model name to use any model you have pulled: `(ollama "hi" "llama3.2")`. Speed depends on your hardware; small 4B models run well on a laptop.

# Web search with Exa and Brave

File: `search.lisp`

Two search APIs, one calling convention: `esearch` and `bsearch` each take a query string and return a list of `(title url text)` triples.

## The code

```lisp
;; sbcl --script search.lisp (Exa and Brave Search APIs)
#-quicklisp (load "~/quicklisp/setup.lisp")
(ql:quickload :com.inuoe.jzon :silent t)

(defun curl-json (&rest args)
  (com.inuoe.jzon:parse
   (uiop:run-program (list* "curl" "-s" args) :output :string)))

(defun api-key (name)
  (or (uiop:getenv name) (error "~a is not set" name)))

(defun unescape (s)
  "Decode the few HTML entities that show up in search snippets."
  (when s
    (loop for (from . to) in '(("&#x27;" . "'") ("&#39;" . "'")
                               ("&quot;" . "\"") ("&lt;" . "<")
                               ("&gt;" . ">") ("&amp;" . "&"))
          do (loop for i = (search from s)
                     then (search from s :start2 (+ i (length to)))
                   while i
                   do (setf s (concatenate 'string (subseq s 0 i) to
                                           (subseq s (+ i (length from))))))
          finally (return s))))

(defun results (items text-key)
  "List of (title url text) for each hit."
  (map 'list
       (lambda (h)
         (list (unescape (gethash "title" h))
               (gethash "url" h)
               (unescape (gethash text-key h))))
       items))

(defun esearch (query &optional (n 5))
  (results
   (gethash "results"
            (curl-json
             "https://api.exa.ai/search"
             "-H" (format nil "x-api-key: ~a"
                          (api-key "EXA_SEARCH_API_KEY"))
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
                   (api-key "BRAVE_SEARCH_API_KEY"))
      "-H" "Accept: application/json"
      "--data-urlencode" (format nil "q=~a" query)
      "--data-urlencode" (format nil "count=~d" n)
      "--data-urlencode" "text_decorations=false")))
   "description"))

(print (esearch "Common Lisp SPARQL client" 3))
(print (bsearch "Sedona Arizona hiking" 3))
```

## How it works

- `curl-json` is a small, reusable helper: run `curl -s` with any arguments and parse the reply as JSON. `list*` puts `"curl" "-s"` in front of the caller's arguments.
- `api-key` reads an environment variable and signals an error if it is unset, so a missing key fails at once instead of going out as the text `NIL`.
- `results` gives both APIs the same output shape. The two engines differ in one detail (Exa returns page content under the key `text`, Brave returns a snippet under `description`), so the text key is a parameter.
- `unescape` decodes the few HTML entities (`&#x27;`, `&quot;`, `&amp;`, ...) that search snippets contain. The inner `loop` restarts each `search` just past the text it inserted, so it never decodes a decoded `&` a second time.
- `esearch` POSTs JSON and asks Exa for up to 300 characters of page text per hit.
- `bsearch` uses `curl -G` with `--data-urlencode` to build a URL-encoded GET request, the right choice when parameters go in the query string rather than a JSON body. The `text_decorations=false` parameter tells Brave not to wrap matching words in `<strong>` tags.

## Running it

```bash
$ export EXA_SEARCH_API_KEY=...
$ export BRAVE_SEARCH_API_KEY=...
$ sbcl --script search.lisp
```

The program prints two lists, one per engine; each element is a `(title url text)` list. Actual output, with long README metadata lines in the Exa snippets cut:

```text
(("mark-watson/sparql" "https://github.com/mark-watson/sparql"
  "# Repository: mark-watson/sparql

Common Lisp SPARQL client code - see book \"Loving Common Lisp,
or the Savvy Programmer's Secret Weapon\"

- Primary language: Common Lisp ...")
 ("madnificent/cl-fuseki" "https://github.com/madnificent/cl-fuseki"
  "# madnificent/cl-fuseki

Common Lisp library for connecting to SPARQL endpoints.

- License: MIT License ...")
 ("mmontone/cl-sparql" "https://github.com/mmontone/cl-sparql"
  "# mmontone/cl-sparql

SPARQL query builder for Common Lisp

- License: MIT License ..."))

(("Hiking in Sedona, Arizona" "https://visitsedona.com/things-to-do/hiking/"
  "Sedona and the Verde Valley offer some of the most picturesque
hikes in the world. There are dozens of options to keep the novice
and experienced hiker delighted for many days–trails along rivers,
trails on mesas and high up in the mountains, ...")
 ("10 Best trails and hikes in Sedona | AllTrails"
  "https://www.alltrails.com/us/arizona/sedona"
  "Apart from the shuttle service, ... The Cathedral Rock hike is a
challenging yet beautiful trail in Sedona that offers great views of
the unique natural rock... ... An amazing natural wonder, Devil's
Bridge, is located near Sedona in Arizona's ...")
 ("The Best Hikes in Sedona, Arizona | A Hiking Travel Guide"
  "https://zannavandijk.co.uk/the-best-hikes-in-sedona/"
  "This is a relatively easy hike with non-stop views of iconic Sedona
rock formations. The trail starts as a loop around the butte and then
you have the option of adding on the climb up Bell Rock which I highly
recommend, the views are incredible!"))
```

Search results change over time, so your hits will differ. `Devil's Bridge` prints with a real apostrophe: Brave sent `Devil&#x27;s`, and `unescape` decoded it.

## Using it

Use these two functions for retrieval-augmented generation: search, then put the `(title url text)` triples into a prompt for the Gemini or Ollama chapters. Exa is a neural search engine and often finds related pages that share no keywords with the query; Brave is a classic keyword index with its own crawl of the web. Running both and merging the results is a cheap way to improve recall.

# Querying knowledge graphs with SPARQL

File: `sparql.lisp`

DBpedia and Wikidata are large public knowledge graphs, and both answer SPARQL queries over HTTP. This program turns a query string into a list of Lisp association lists.

## The code

```lisp
;; sbcl --script sparql.lisp   (needs Quicklisp + curl)
#-quicklisp (load "~/quicklisp/setup.lisp")
(ql:quickload :com.inuoe.jzon :silent t)

(defun sparql (endpoint query)
  "Returns a list of rows, each row an alist of (variable . value),
with variables in SELECT order. Unbound variables are omitted."
  (let* ((cmd (list "curl" "-s" "-G" endpoint
                    "-H" "Accept: application/sparql-results+json"
                    "-A" "sparql.lisp/1.0 (Common Lisp example)"
                    "--data-urlencode"
                    (concatenate 'string "query=" query)))
         (raw (uiop:run-program cmd :output :string))
         (json (com.inuoe.jzon:parse raw))
         (vars (gethash "vars" (gethash "head" json)))
         (bindings (gethash "bindings" (gethash "results" json))))
    (map 'list
         (lambda (row)
           (loop for var across vars
                 for b = (gethash var row)
                 when b collect (cons var (gethash "value" b))))
         bindings)))

(defun dbpedia (query)
  (sparql "https://dbpedia.org/sparql" query))

(defun wikidata (query)
  (sparql "https://query.wikidata.org/sparql" query))

(print (dbpedia
        "SELECT ?birth WHERE { dbr:Bill_Gates dbo:birthDate ?birth }"))
(print (wikidata
        (concatenate
         'string
         "SELECT ?label WHERE { "
         "wd:Q5284 rdfs:label ?label FILTER(LANG(?label) = \"en\") }")))
```

## How it works

- The request is a GET with the query URL-encoded by `--data-urlencode`, plus an `Accept` header that asks for the standard JSON results format. Some endpoints, Wikidata in particular, ask clients to send a descriptive `User-Agent` (`-A`).
- In the JSON results format, `head.vars` lists the query's variables in `SELECT` order, and each solution in `results.bindings` maps variable names to binding objects; a binding's `value` key holds the lexical form. The inner `loop` walks `vars` (not the hash table, whose key order is unspecified), so each row lists its columns in the order you wrote them. A variable that an `OPTIONAL` clause leaves unbound has no entry in the solution, and `when b` drops it from that row.
- `dbpedia` and `wikidata` are one-line wrappers that call `sparql` with each endpoint.

## Running it

```bash
$ sbcl --script sparql.lisp
```

The first query asks DBpedia for Bill Gates's birth date and prints a one-row, one-column result:

```text
((("birth" . "1955-10-28")))
```

The second asks Wikidata for the English label of the entity `wd:Q5284` (Bill Gates). Actual output:

```text
((("label" . "Bill Gates")))
```

Column order and unbound variables matter once a query has several variables. This query asks DBpedia for two people and an `OPTIONAL` death date. Actual output in a REPL after loading the file:

```lisp
* (dbpedia "SELECT ?name ?birth ?death WHERE {
              VALUES ?p { dbr:Alan_Turing dbr:Bill_Gates }
              ?p foaf:name ?name ; dbo:birthDate ?birth .
              OPTIONAL { ?p dbo:deathDate ?death } }")
((("name" . "Alan Turing") ("birth" . "1912-06-23") ("death" . "1954-06-07"))
 (("name" . "Bill Gates") ("birth" . "1955-10-28")))
```

Each row lists its columns in `SELECT` order, and Bill Gates's row has no `death` entry.

## Using it

Knowledge graphs add precise facts to the text sources used elsewhere in this book: SPARQL returns exact, citable values rather than snippets. Try asking DBpedia for a topic's abstract (`dbo:abstract`), or use Wikidata's `wdt:` properties to follow relationships. The triple-store chapter later in the book builds a small version of the same idea (pattern matching with variables) over in-memory data.

# JavaScript-rendered pages with Lightpanda

File: `lightpanda.lisp`

Some pages show little content until JavaScript runs. Lightpanda is a small headless browser built for this case; here Lisp runs it as a subprocess.

## The code

```lisp
;; sbcl --script lightpanda.lisp   (needs the lightpanda binary on PATH)
(require :asdf)

(defun lightpanda (url &optional (dump "html"))
  "DUMP is a text format: html, markdown, semantic_tree,
semantic_tree_text, or structured_data."
  (uiop:run-program
   (list "lightpanda" "fetch" "--dump" dump
         "--log-level" "warn" url)
   :output :string))

(defun links (html)
  (loop for i = (search "href=\"" html)
        then (search "href=\"" html :start2 end)
        for end = (and i (position #\" html :start (+ i 6)))
        while end collect (subseq html (+ i 6) end)))

(print (lightpanda "https://markwatson.com/" "markdown"))
(print (links (lightpanda "https://markwatson.com/")))
```

## How it works

- `lightpanda fetch` renders the page (JavaScript included) and dumps it as text: raw `html`, a `markdown` conversion, the `semantic_tree` variants that expose the page's structure, or `structured_data` (JSON-LD, OpenGraph, and meta tags as JSON). Lightpanda can also dump `pdf` and `png`, but those are binary and this function returns a string, so it sticks to the text formats. `--log-level warn` keeps diagnostics off standard output so the return value stays clean.
- `links` is a simple string scan, not an HTML parser: `search` finds each `href="` marker and `position` finds the closing quote. That works for the tidy HTML a renderer emits; for arbitrary HTML, use the parser in the web-scraping chapter.

## Running it

Install Lightpanda so the `lightpanda` binary is on your `PATH`, then:

```bash
$ sbcl --script lightpanda.lisp
```

The first `print` shows the home page as a Markdown string (headings, links, and text without HTML markup). Actual output, abridged:

```text
"[Mark Watson ](https://markwatson.com/#)
- [Systems Thinking](https://markwatson.com/#systems)
- [Books](https://markwatson.com/#books)
- [Connect](https://markwatson.com/#connect)
- [Free Mentoring](https://markwatson.com/#mentoring)
- [Flagstaff Arizona](https://markwatson.com/flagstaff.html)
- [Blogspot](https://mark-watson.blogspot.com/)
- [Substack](https://marklwatson.substack.com/)
- [GitHub](https://github.com/mark-watson)
- [Leanpub](https://leanpub.com/u/markwatson)

# Mark Watson

****Systems Thinker & Generalist AI Expert****

Synthesizing complex technologies across 40\\+ years of computing.
I approach artificial intelligence through a systems\\-thinking lens
by bridging modern LLMs, neural networks, knowledge graphs, and
symbolic reasoning with large\\-scale distributed architectures.

Self\\-funded open source researcher and author, with engineering
and advisory experience for organizations including **Google**,
**Mind AI**, **Capital One**, **Disney**, **SAIC/Leidos**, **DARPA**,
**Babylist**, **Olive AI**, and **CompassLabs**.
...
"
```

The second prints a list of the page's href strings. Actual output, abridged:

```text
("/index.css" "#" "#systems" "#books" "#connect" "#mentoring"
 "/flagstaff.html" "https://mark-watson.blogspot.com/"
 "https://marklwatson.substack.com" "https://github.com/mark-watson"
 "https://leanpub.com/u/markwatson" "#systems" "#books" "#connect"
 "https://leanpub.com/pythonai/read" "https://leanpub.com/pythonai"
 "https://leanpub.com/lovinglisp/read" "https://leanpub.com/lovinglisp"
 "https://leanpub.com/clojureai/read" "https://leanpub.com/clojureai"
 "https://leanpub.com/haskell-cookbook/read"
 "https://leanpub.com/haskell-cookbook/" "https://leanpub.com/javaai/read"
 "https://leanpub.com/javaai" "https://leanpub.com/hy-lisp-python/read"
 "https://leanpub.com/hy-lisp-python"
 ...
 "https://leanpub.com/u/markwatson" "/flagstaff.html" "/privacy.html")
```

## Using it

The `markdown` dump suits AI pipelines: it turns a JavaScript-heavy page into compact text you can pass to a model from the Gemini or Ollama chapters. For interactive work (clicking links, filling in forms, waiting for content), run `lightpanda serve`, which exposes the Chrome DevTools Protocol over a WebSocket, and control it from a CDP client. This chapter covers the simple case: one subprocess call per page.

# Web scraping with Plump

File: `webscraping.lisp`

When a page is plain HTML, you do not need a browser: fetch it with `curl`, parse it into a DOM with Plump, and walk the tree.

## The code

```lisp
;; sbcl --script webscraping.lisp   (needs Quicklisp + curl)
#-quicklisp (load "~/quicklisp/setup.lisp")
(ql:quickload '(:plump :clss :cl-ppcre) :silent t)

(defun fetch (url)
  (plump:parse
   (uiop:run-program
    (list "curl" "-fsL" "-A" "Mozilla/5.0" url) :output :string)))

(defun text (node)
  "Text of NODE, skipping boilerplate; block tags become newlines."
  (let ((tag (and (plump:element-p node)
                  (string-downcase (plump:tag-name node)))))
    (cond ((plump:text-node-p node)
           (cl-ppcre:regex-replace-all "\\s+" (plump:text node) " "))
          ((member tag
                   '("script" "style" "head" "nav" "header"
                     "footer" "noscript" "iframe")
                   :test #'equal)
           "")
          ((plump:nesting-node-p node)
           (let ((s (format nil "~{~a~}"
                            (map 'list #'text (plump:children node)))))
             (if (member tag '("p" "div" "li" "br" "tr" "h1" "h2"
                               "h3" "h4" "h5" "h6" "section"
                               "article" "ul" "ol" "pre" "blockquote")
                          :test #'equal)
                 (format nil "~%~a~%" s)
                 s)))
          (t ""))))

(defun clean (s)
  (string-trim
   '(#\Space #\Newline)
   (cl-ppcre:regex-replace-all
    "\\n{3,}"
    (cl-ppcre:regex-replace-all "(?m)^ +| +$" s "")
    (format nil "~%~%"))))

(defun dom (page)
  "PAGE is either a URL string or an already-parsed plump DOM."
  (if (stringp page) (fetch page) page))

(defun headers (page)
  (map 'list (lambda (h) (clean (text h)))
       (clss:select "h1,h2,h3,h4,h5,h6" (dom page))))

(defun page-text (page) (clean (text (dom page))))

(let ((root (fetch "https://markwatson.com")))
  (print (headers root))
  (format t "~%~%~a~%" (page-text root)))
```

## How it works

- Three libraries do most of the work: `plump` parses HTML into a DOM, `clss` adds CSS-selector queries over that DOM, and `cl-ppcre` provides regular expressions for whitespace cleanup.
- `fetch` runs `curl -fsL` with a browser-like `User-Agent` and parses the reply. `-L` follows redirects, and `-f` makes curl exit with an error on an HTTP 404 or 500 instead of returning the server's error page as content; `uiop:run-program` then signals a `subprocess-error`.
- `text` does the main work: a recursive DOM walk that skips boilerplate elements (`script`, `style`, `nav`, `header`, `footer`, ...), collapses whitespace inside text nodes, and turns block-level tags into newlines so the output keeps the page's paragraph structure.
- `clean` tidies the result: it strips spaces at the start and end of each line, collapses runs of three or more newlines into one blank line, and trims the ends.
- `headers` uses `clss`: one CSS selector finds all `h1` through `h6` elements.
- `dom` lets `headers` and `page-text` accept either a URL or a parsed DOM. The demo uses this to download the page once and run both functions on the same tree.

## Running it

```bash
$ sbcl --script webscraping.lisp
```

Actual output (showing the full `headers` list and the opening paragraphs of `page-text`):

```text
("Mark Watson" "Systems Thinking & Generalist AI"
 "Read My Books — Many for Free" "Connect & Interests"
 "Free Mentoring for Technical Projects" "Holistic Systems Architecture"
 "Neuro-Symbolic Integration" "Multi-Paradigm Polyglot"
 "40+ Years of Long-Horizon Vision" "Loving Lisp Is Being Rewritten"
 "Writings & Blogs" "Open Source" "Consulting" "Interests & Music"
 "How It Works" "Additional eBooks on Leanpub"
 "Traditional Publications (Springer-Verlag, McGraw-Hill, Morgan Kaufmann)"
 "Free Semantic Web PDFs & Material")

Mark Watson

Systems Thinker & Generalist AI Expert

Synthesizing complex technologies across 40+ years of computing. I
approach artificial intelligence through a systems-thinking lens by
bridging modern LLMs, neural networks, knowledge graphs, and symbolic
reasoning with large-scale distributed architectures.

Self-funded open source researcher and author, with engineering and
advisory experience for organizations including Google, Mind AI,
Capital One, Disney, SAIC/Leidos, DARPA, Babylist, Olive AI, and
CompassLabs.

40+ Years in AI

20+ Books Published

55 US Patents
...
```

## Using it

`page-text` pairs well with the summarizer chapter: summarize any web page with `(summarize (page-text url) 3)`. `headers` alone is handy for skimming a page's structure. Compared with the Lightpanda chapter, this approach is faster and needs no external binary, but it never runs JavaScript.

# Automating macOS with AppleScript

File: `osascript.lisp`

macOS exposes Mail, Calendar, Reminders, Messages, and Safari to AppleScript, and the `osascript` utility runs AppleScript from the command line. From Lisp, each of those apps is one `uiop:run-program` call away.

## The code

```lisp
;;;; osascript.lisp -- tiny macOS automation via osascript.
;;;; A library, not a script: (load "osascript.lisp") in a REPL,
;;;; then try the calls in the Examples comment at the bottom.
;;;; Needs Automation permission for your terminal:
;;;; System Settings > Privacy & Security.
;;;; READ-RECENT-IMESSAGES also needs Full Disk Access; SAFARI-LOGIN
;;;; needs Safari > Develop > Allow JavaScript from Apple Events.
;;;; Keep credentials out of this file.
(require :asdf)

(defun osascript (script)
  (multiple-value-bind (out err code)
      (uiop:run-program (list "osascript" "-e" script)
                        :output :string
                        :error-output :string
                        :ignore-error-status t)
    (flet ((trim (s) (string-trim '(#\Space #\Newline #\Return) s)))
      (if (zerop code)
          (trim out)
          (error "osascript: ~a" (trim err))))))

;;; ~S quotes Lisp strings as valid AppleScript and JavaScript literals.
(defun mail-unread-count ()
  (parse-integer
   (osascript
    "tell application \"Mail\" to return unread count of inbox")))

(defun get-todays-events ()
  (remove ""
          (uiop:split-string
           (osascript "tell application \"Calendar\"
  set t0 to current date
  set time of t0 to 0
  set out to {}
  repeat with c in calendars
    set out to out & (summary of every event of c ¬
      whose start date >= t0 and start date < t0 + days)
  end repeat
  set AppleScript's text item delimiters to \"|\"
  return out as string
end tell") :separator "|") :test #'string=))

(defun send-imessage (phone message)
  (osascript
   (format nil
    (concatenate
     'string
     "tell application \"Messages\" to send ~S to buddy ~S "
     "of (1st service whose service type = iMessage)")
    message phone)))

(defun add-reminder (name)
  (osascript
   (format nil
    (concatenate
     'string
     "tell application \"Reminders\" to return id of "
     "(make new reminder with properties {name:~S})")
    name)))

(defun read-recent-imessages (&optional (limit 5))
  (check-type limit (integer 1))
  (let ((db (namestring
             (merge-pathnames "Library/Messages/chat.db"
                              (user-homedir-pathname))))
        (sql (format nil
              (concatenate
               'string
               "SELECT m.is_from_me, h.id AS sender, m.text "
               "FROM message m LEFT JOIN handle h ON "
               "m.handle_id = h.ROWID WHERE m.text IS NOT NULL "
               "ORDER BY m.date DESC LIMIT ~d;")
              limit)))
    (uiop:run-program (list "sqlite3" "-json" db sql)
                      :output :string)))

(defun safari-login (url user password
                     &key (user-id "username")
                          (password-id "password")
                          (form-id "login-form")
                          (timeout 30))
  (let ((js (format nil
             (concatenate
              'string
              "document.getElementById(~S).value = ~S; "
              "document.getElementById(~S).value = ~S; "
              "document.getElementById(~S).submit();")
             user-id user password-id password form-id)))
    (osascript (format nil "tell application \"Safari\"
  set d to make new document with properties {URL:~S}
  repeat ~d times
    delay 0.5
    if (do JavaScript \"document.readyState\" in d) is \"complete\" then
      return (do JavaScript ~S in d)
    end if
  end repeat
end tell
error \"Safari page did not load within ~d seconds\""
                       url (* 2 timeout) js timeout))))

;;; Examples
;; (osascript "return 1 + 10")
;; (mail-unread-count)
;; (get-todays-events)
;; (add-reminder "Buy milk")
;; (send-imessage "+15551234567" "Hello from Lisp")
;; (read-recent-imessages 3)
;; (safari-login "https://leanpub.com/author/royalties/summary"
;;               (uiop:getenv "LEANPUB_USER")
;;               (uiop:getenv "LEANPUB_PASSWORD"))
```

## How it works

- `osascript` (the Lisp function) captures stdout, stderr, and the exit code with `multiple-value-bind`; a non-zero exit signals a Lisp error that carries AppleScript's own error message.
- The `~S` format directive handles quoting in this file: it prints a Lisp string as a quoted, escaped string literal, which is *also* valid AppleScript (and JavaScript) syntax. That makes it safe to insert strings into scripts.
- `get-todays-events` shows a common AppleScript pattern: build a list, set `text item delimiters` to a separator, return the list as a string, then split it in Lisp with `uiop:split-string`.
- `send-imessage` uses the older `buddy`/`service` terms from the Messages scripting dictionary. Recent macOS releases also accept the newer `participant`/`account` terms; if your version rejects `buddy`, open the Messages dictionary in Script Editor and adjust the one line.
- `read-recent-imessages` skips AppleScript and queries the Messages SQLite database with `sqlite3 -json`, which is why it needs Full Disk Access. `check-type` guards the `limit` parameter that the function inserts into the SQL. On recent macOS versions, many message bodies sit in the binary `attributedBody` column with `text` set to `NULL`, so the query misses some messages. The function returns the raw JSON string to keep the file free of Quicklisp dependencies; parse it with `jzon` if you have it loaded.
- `safari-login` opens a page, checks `document.readyState` every half second until the page loads (or signals an error after `timeout` seconds), then runs JavaScript that fills in the username and password fields and submits the form.

## Running it

This is the one file in the book that is a library rather than a script: load it in a REPL, since the examples at the bottom are comments. Grant your terminal Automation permission (macOS asks the first time), grant Full Disk Access for `read-recent-imessages`, and turn on *Safari → Develop → Allow JavaScript from Apple Events* for `safari-login`.

```lisp
* (load "osascript.lisp")
* (osascript "return 1 + 10")
"11"
```

I ran the call above, and `"11"` is its real output. The other functions appear as calls, not transcripts, because their results depend on your machine's state (inbox count, today's calendar) or change it (sending a message, adding a reminder), so try them in your own REPL.

## Using it

Use this chapter as a template: you can wrap any AppleScript you find online the same way. Keep credentials in environment variables (as the last example shows), not in source. These functions combine well with the LLM chapters: summarize today's calendar, send yourself an iMessage when a script finishes, or check your Leanpub royalties on a schedule.

# Bayesian inference

File: `bayes.lisp`

Fourteen lines of Lisp implement Bayes' theorem as a reusable update function, and the demo reproduces the well-known medical "base-rate fallacy" result.

Bayes' theorem computes the posterior probability of a hypothesis given evidence:

```$
P(H \mid E) = \frac{P(E \mid H) \, P(H)}{P(E)}
```

The program works with whole distributions: a distribution is an alist of `(hypothesis . probability)` pairs, and normalizing after each update takes care of the denominator `P(E)`$.

## The code

```lisp
;; sbcl --script bayes.lisp (Bayesian inference)

(defun bayes-normalize (dist)
  (let ((sum (reduce #'+ dist :key #'cdr)))
    (when (zerop sum)
      (error "The evidence has zero probability under every hypothesis"))
    (mapcar (lambda (p) (cons (car p) (/ (cdr p) sum))) dist)))

(defun bayes-update (dist evidence likelihood-fn)
  (bayes-normalize
   (mapcar (lambda (p)
             (cons (car p)
                   (* (cdr p)
                      (funcall likelihood-fn (car p) evidence))))
           dist)))

(defun map-hypothesis (dist)
  (reduce (lambda (a b) (if (> (cdr a) (cdr b)) a b)) dist))

;; Demo: Medical screening base-rate fallacy
;; Disease prevalence: 1%. Test: 95% sensitivity (true +), 5% false +
(let* ((prior '((has-disease . 0.01) (healthy . 0.99)))
       (likelihood (lambda (hyp test-result)
                     (case hyp
                       (has-disease (if (eq test-result '+) 0.95 0.05))
                       (healthy
                        (if (eq test-result '+) 0.05 0.95)))))
       (post1 (bayes-update prior '+ likelihood))
       (post2 (bayes-update post1 '+ likelihood)))
  (format t "Prior:         ~{~a: ~,4f~^, ~}~%"
          (mapcan (lambda (p) (list (car p) (cdr p))) prior))
  (format t "After 1st (+): ~{~a: ~,4f~^, ~}  -> MAP: ~a~%"
          (mapcan (lambda (p) (list (car p) (cdr p))) post1)
          (car (map-hypothesis post1)))
  (format t "After 2nd (+): ~{~a: ~,4f~^, ~}  -> MAP: ~a~%"
          (mapcan (lambda (p) (list (car p) (cdr p))) post2)
          (car (map-hypothesis post2))))
```

## How it works

- `bayes-update` multiplies each prior probability by the likelihood of the evidence under that hypothesis, then `bayes-normalize` divides by the total so the probabilities sum to one again. That multiply-then-normalize pair *is* Bayes' theorem. If the total is zero (evidence that every hypothesis rules out), no posterior exists, so `bayes-normalize` signals an error instead of dividing by zero.
- The caller passes the likelihood as a function, so the same updater works for any hypothesis and evidence types.
- `map-hypothesis` returns the most probable pair, the maximum a posteriori (MAP) estimate.
- `reduce` with `:key #'cdr` sums the probabilities without a loop; the `~{...~^, ~}` format directive prints the alist as a comma-separated list.

## Running it

```bash
$ sbcl --script bayes.lisp
```

Actual output:

```text
Prior:         HAS-DISEASE: 0.0100, HEALTHY: 0.9900
After 1st (+): HAS-DISEASE: 0.1610, HEALTHY: 0.8390  -> MAP: HEALTHY
After 2nd (+): HAS-DISEASE: 0.7848, HEALTHY: 0.2152  -> MAP: HAS-DISEASE
```

The second line shows the fallacy: even after a positive result from a "95% accurate" test, a patient with a disease that affects 1% of people probably does *not* have it, because the posterior is only about 16%:

```$
P(D \mid +) = \frac{0.95 \cdot 0.01}{0.95 \cdot 0.01 + 0.05 \cdot 0.99} \approx 0.161
```

Using that posterior as the prior for a second, independent positive test (`post2`) raises the probability to about 78%.

## Using it

Swap in your own hypotheses and likelihoods: spam classification, sensor fusion, diagnosis with more than two hypotheses. One caveat: sequential `bayes-update` calls assume each piece of evidence is conditionally independent given the hypothesis, so correlated evidence (say, the same test run twice) makes the posterior overconfident.

# Ranking documents with BM25

File: `bm25.lisp`

Search engines have used BM25 to rank documents for decades. This program implements it from scratch in about forty lines: tokenize a small corpus, score documents against a query, and return ranked hits.

For term `t`$ occurring in `n_t`$ of `N`$ documents, the inverse document frequency is:

```$
\mathrm{idf}(t) = \ln\!\left(1 + \frac{N - n_t + 0.5}{n_t + 0.5}\right)
```

and the score of document `d`$ for query `q`$ is:

```$
\mathrm{score}(d, q) = \sum_{t \in q} \mathrm{idf}(t)\; \frac{f(t,d)\,(k_1 + 1)}{f(t,d) + k_1 \left(1 - b + b\, \frac{|d|}{\mathrm{avgdl}}\right)}
```

with the standard defaults `k_1 = 1.5`$ and `b = 0.75`$.

## The code

```lisp
;; sbcl --script bm25.lisp   (Okapi BM25 document ranking)

(defun tokenize (text)
  (loop with len = (length text) and words = nil and acc = nil
        for i from 0 below len
        for ch = (char text i)
        do (if (alphanumericp ch)
               (push (char-downcase ch) acc)
               (when acc
                 (push (coerce (nreverse acc) 'string) words)
                 (setf acc nil)))
        finally (when acc (push (coerce (nreverse acc) 'string) words))
                (return (nreverse words))))

(defun bm25-search (corpus query &key (k1 1.5) (b 0.75))
  (let* ((docs (mapcar #'tokenize corpus))
         (n (length corpus))
         (lens (mapcar #'length docs))
         (avgdl (/ (reduce #'+ lens) (float (max 1 n))))
         (idfs                          ; ((term . idf) ...), once per term
           (loop for term in (remove-duplicates (tokenize query)
                                                :test #'string=)
                 for df = (count-if (lambda (d)
                                      (member term d :test #'string=))
                                    docs)
                 collect (cons term
                               (log (+ 1.0 (/ (+ (- n df) 0.5)
                                              (+ df 0.5))))))))
    (sort (loop for doc in docs
                for raw in corpus
                for len in lens
                for score =
                (loop for (term . idf) in idfs
                      for tf = (count term doc :test #'string=)
                      when (> tf 0)
                      sum (* idf
                             (/ (* tf (+ k1 1.0))
                                (+ tf (* k1
                                         (+ (- 1.0 b)
                                            (* b (/ len avgdl))))))))
                when (> score 0.0)
                collect (list score raw))
          #'> :key #'car)))

;; Demo: Document corpus search
(let ((corpus
        (list
         (concatenate 'string
          "Common Lisp is a general-purpose programming language "
          "with powerful macros.")
         (concatenate 'string
          "Python is an interpreted language known for data science "
          "and machine learning.")
         (concatenate 'string
          "Deep learning models require automatic differentiation "
          "and gradient optimization.")
         (concatenate 'string
          "Macros in Common Lisp enable syntactic metaprogramming "
          "and DSL design.")
         (concatenate 'string
          "Okapi BM25 is an information retrieval ranking function "
          "used in search engines."))))
  (format t "Corpus size: ~a documents~%" (length corpus))
  (dolist (query '("Common Lisp macros" "search ranking" "learning"))
    (format t "~%Query: ~s~%" query)
    (dolist (hit (bm25-search corpus query))
      (format t "  [score: ~5,3f] ~a~%" (first hit) (second hit)))))
```

## How it works

- `tokenize` is a hand-written scanner built with `loop`: it collects alphanumeric characters (downcased) and emits a word whenever a non-alphanumeric character ends the run.
- The function computes `idfs` once per query, before any scoring: an alist of `(term . idf)` pairs, where `count-if` counts the documents that contain each term. Computing it per document would rescan the whole corpus for every document and turn a linear pass into a quadratic one.
- The scoring `loop` steps through documents, raw strings, and lengths in parallel (`for ... for ... for ...`) and computes each document's score as a sum over unique query terms. The inner `loop for (term . idf) in idfs` destructures each pair. `remove-duplicates` on the query terms stops a repeated word from counting twice.
- The division by `avgdl` is safe even for a corpus of empty strings: it runs only when `tf > 0`, which means the document, and so the average length, is non-empty.
- The `k_1`$ parameter controls term-frequency saturation, and `b`$ controls how much the score penalizes documents longer than the average length `\mathrm{avgdl}`$.

## Running it

```bash
$ sbcl --script bm25.lisp
```

Actual output:

```text
Corpus size: 5 documents

Query: "Common Lisp macros"
  [score: 2.717] Macros in Common Lisp enable syntactic metaprogramming and DSL design.
  [score: 2.605] Common Lisp is a general-purpose programming language with powerful macros.

Query: "search ranking"
  [score: 2.641] Okapi BM25 is an information retrieval ranking function used in search engines.

Query: "learning"
  [score: 0.946] Deep learning models require automatic differentiation and gradient optimization.
  [score: 0.834] Python is an interpreted language known for data science and machine learning.
```

The output shows length normalization at work. For "learning", both matching documents contain the word once, but the 9-token deep-learning sentence beats the 12-token Python sentence: the same match counts for more in a shorter document. Length also decides "Common Lisp macros": both documents contain all three query words, and the 10-token sentence scores higher than the 11-token one. "search" and "ranking" each appear in only one document, so they get the highest `idf` weight, and that document scores high on a two-word query.

## Using it

BM25 is a strong baseline for any local keyword search: your notes, a set of docs, log files. It also pairs well with the vector-store chapter; hybrid search systems often merge BM25 (exact keyword match) with embedding similarity (semantic match). The `(score document)` lists come back sorted, ready to cut to a top-`k`$ list.

# Associative memory with Hopfield networks

File: `hopfield.lisp`

A Hopfield network stores patterns as attractors (stable states) of a dynamical system: train it with Hebbian learning, then present a corrupted pattern and let the network settle into the nearest stored pattern.

Training on bipolar patterns `x^{(p)} \in \{-1, +1\}^N`$ sets the weights to the outer-product sum:

```$
w_{ij} = \sum_{p} x_i^{(p)} x_j^{(p)} \quad (i \neq j), \qquad w_{ii} = 0
```

Recalling iterates the sign rule `s_i \leftarrow \mathrm{sgn}\!\left(\sum_j w_{ij} s_j\right)`$, which never increases the energy:

```$
E(s) = -\frac{1}{2} \sum_{i=1}^{N} \sum_{j=1}^{N} w_{ij}\, s_i\, s_j
```

when neurons update one at a time, so the energy falls until the state reaches a stored pattern.

## The code

```lisp
;; sbcl --script hopfield.lisp (Hopfield associative neural network)

(defun hopfield-train (patterns size)
  (let ((w (make-array (list size size) :initial-element 0)))
    (dolist (p patterns w)
      (dotimes (i size)
        (dotimes (j size)
          (unless (= i j)
            (incf (aref w i j) (* (nth i p) (nth j p)))))))))

(defun hopfield-recall (w input &optional (max-sweeps 10))
  "Update neurons one at a time, in place, until a full sweep changes
nothing. Returns the final state and the number of sweeps used."
  (let ((state (copy-seq input))
        (n (length input)))
    (dotimes (sweep max-sweeps (values state max-sweeps))
      (let ((changed nil))
        (dotimes (i n)
          (let* ((sum (loop for j below n
                            sum (* (aref w i j) (nth j state))))
                 (new (if (>= sum 0) 1 -1)))
            (unless (= new (nth i state))
              (setf (nth i state) new
                    changed t))))
        (unless changed
          (return (values state (1+ sweep))))))))

(defun hopfield-energy (w state)
  (- (* 0.5
        (loop for i below (length state)
              sum (loop for j below (length state)
                        sum (* (aref w i j)
                               (nth i state)
                               (nth j state)))))))

(defun show-pattern (pat &optional (width 4))
  (loop for i from 0 below (length pat)
        do (format t "~a " (if (= (nth i pat) 1) "#" "."))
        when (zerop (mod (1+ i) width)) do (terpri)))

;; Demo: Train on 16-bit 'X' and 'O' patterns, recall corrupted pattern
(let* ((pattern-x '( 1 -1 -1  1
                    -1  1  1 -1
                    -1  1  1 -1
                     1 -1 -1  1))
       (pattern-o '( 1  1  1  1
                     1 -1 -1  1
                     1 -1 -1  1
                     1  1  1  1))
       (w (hopfield-train (list pattern-x pattern-o) 16))
       ;; Corrupt pattern-x by flipping 3 bits (indices 0, 5, 10)
       (noisy (let ((cp (copy-seq pattern-x)))
                (dolist (idx '(0 5 10) cp)
                  (setf (nth idx cp) (- (nth idx cp)))))))
  (format t "Original Pattern 'X' (Energy: ~,1f):~%"
          (hopfield-energy w pattern-x))
  (show-pattern pattern-x)
  (format t "~%Noisy Pattern with 3 bit-flips (Energy: ~,1f):~%"
          (hopfield-energy w noisy))
  (show-pattern noisy)
  (multiple-value-bind (recalled sweeps) (hopfield-recall w noisy)
    (format t "~%Recalled Associative Memory (Energy: ~,1f):~%"
            (hopfield-energy w recalled))
    (show-pattern recalled)
    (format t "~%Recovered perfectly? ~a (stable after ~d sweeps)~%"
            (equal recalled pattern-x) sweeps)))
```

## How it works

- `hopfield-train` adds the outer product of each pattern into an `N \times N`$ weight matrix and skips the diagonal, so the whole learning rule is one `incf`.
- `hopfield-recall` copies the input (so it does not change the caller's list) and sweeps over the neurons, updating each one *in place*, so later neurons in the same sweep see their neighbors' new values. These *asynchronous* updates guarantee that the energy never rises. (Synchronous updates, where every neuron reads the previous sweep's state, can flip between two states forever.) `(if (>= sum 0) 1 -1)` is the sign activation.
- Recall stops when a full sweep changes nothing, meaning the state has reached a fixed point, and returns the number of sweeps as a second value. `max-sweeps` is only a safety limit.
- `hopfield-energy` computes the Lyapunov function above; the demo uses it to show recall making progress.
- `show-pattern` renders a bipolar list as a `#`/`.` grid.

## Running it

```bash
$ sbcl --script hopfield.lisp
```

Actual output:

```text
Original Pattern 'X' (Energy: -144.0):
# . . #
. # # .
. # # .
# . . #

Noisy Pattern with 3 bit-flips (Energy: -52.0):
. . . #
. . # .
. # . .
# . . #

Recalled Associative Memory (Energy: -144.0):
# . . #
. # # .
. # # .
# . . #

Recovered perfectly? T (stable after 2 sweeps)
```

The corrupted pattern starts at energy `-52.0`. The first sweep fixes all three flipped bits and returns the network to the stored `X` at energy `-144.0`; the second sweep changes nothing, which tells `hopfield-recall` to stop.

## Using it

Hopfield networks make good teaching tools for attractor dynamics, Hebbian learning, and energy minimization, all in about sixty lines. Their capacity is small (roughly `0.15N`$ random patterns before patterns interfere), but the same outer-product idea appears again in modern work on associative memory and attention. Try training on the `O` pattern, corrupting *it*, and checking that recall lands on `O`; then store more patterns than the capacity allows and watch the network produce spurious mixtures.

# A tiny triple store

File: `triple-store.lisp`

An RDF-style triple store with a pattern-matching query engine in under thirty lines: variables, unification against the store, and relational joins across patterns.

## The code

```lisp
;; sbcl --script triple-store.lisp (in-memory RDF triple store)

;; A store is a list of (subject predicate object) triples.
;; To keep several stores, rebind it: (let ((*store* nil)) ...)
(defvar *store* nil)

(defun add-triple (s p o)
  (push (list s p o) *store*))

(defun var-p (x)
  (and (symbolp x) (char= (char (symbol-name x) 0) #\?)))

(defun match-triple (pat triple env)
  "ENV extended so that PAT matches TRIPLE, or :FAIL."
  (loop for p in pat for x in triple
        do (cond ((var-p p)
                  (let ((b (assoc p env)))
                    (cond ((null b) (push (cons p x) env))
                          ((not (equal (cdr b) x)) (return :fail)))))
                 ((not (equal p x)) (return :fail)))
        finally (return env)))

(defun query-triples (patterns &optional (store *store*) (envs '(())))
  (if (null patterns) envs
      (query-triples
       (cdr patterns) store
       (loop for env in envs
             append
             (loop for tr in store
                   for next-env = (match-triple (car patterns) tr env)
                   unless (eq next-env :fail) collect next-env)))))

;; Demo: Knowledge graph of thinkers, occupations, and cities
(dolist (tr '((socrates :is-a :philosopher)
              (socrates :lives-in :athens)
              (plato    :is-a :philosopher)
              (plato    :lives-in :athens)
              (descartes :is-a :philosopher)
              (descartes :lives-in :paris)
              (monet    :is-a :painter)
              (monet    :lives-in :paris)
              (voltaire :is-a :writer)
              (voltaire :lives-in :paris)))
  (apply #'add-triple tr))

(format t "Knowledge base triples count: ~a~%" (length *store*))

(format t "~%Query 1: Who is a philosopher?~%")
(dolist (b (query-triples '((?who :is-a :philosopher))))
  (format t "  who: ~a~%" (cdr (assoc '?who b))))

(format t "~%Query 2: Who lives in Paris AND is a philosopher? ~
           (relational join)~%")
(dolist (b (query-triples '((?who :lives-in :paris)
                            (?who :is-a :philosopher))))
  (format t "  who: ~a~%" (cdr (assoc '?who b))))

(format t "~%Query 3: All people in Paris and their occupations:~%")
(dolist (b (query-triples '((?person :lives-in :paris)
                            (?person :is-a ?job))))
  (format t "  ~a is a ~a in Paris~%"
          (cdr (assoc '?person b))
          (cdr (assoc '?job b))))
```

## How it works

- `*store*` is a list of `(subject predicate object)` triples; `add-triple` pushes onto it. To keep several stores, rebind the special variable with `let` (see "Using it" below).
- A "variable" is any symbol whose name starts with `?` (`var-p`), a convention borrowed from SPARQL.
- `match-triple` unifies one pattern with one triple under a binding environment (an alist): a bound variable must match its binding, an unbound variable gets bound, and a literal must be `equal`. It returns the extended environment or the keyword `:fail`.
- `query-triples` performs the join: it passes a *list* of environments through the pattern list. For each pattern it tries every triple against every live environment and keeps the successes. Two patterns that mention the same variable therefore act as a relational join.
- The environments need no copying. `push` never modifies the alist it receives; it adds a new cons in front of it. Each extended environment *shares* its tail with the environment it came from, so a failed match cannot disturb other environments. Lists used this way give you a persistent data structure at no cost.

## Running it

```bash
$ sbcl --script triple-store.lisp
```

Actual output:

```text
Knowledge base triples count: 10

Query 1: Who is a philosopher?
  who: DESCARTES
  who: PLATO
  who: SOCRATES

Query 2: Who lives in Paris AND is a philosopher? (relational join)
  who: DESCARTES

Query 3: All people in Paris and their occupations:
  VOLTAIRE is a WRITER in Paris
  MONET is a PAINTER in Paris
  DESCARTES is a PHILOSOPHER in Paris
```

Query 2 shows the join: the first pattern binds `?who`, and the second pattern succeeds only where that same binding is a philosopher. Only Descartes passes. Results appear in reverse insertion order because `add-triple` uses `push`, which adds each new triple to the front of the list.

## Using it

This is the core of a small Datalog. Add recursive rules or negation-as-failure and you have a little logic language; load it with results from the SPARQL chapter and you can cache and join remote knowledge-graph data locally. For a handful of triples in a script, it is often all the "database" you need.

Because `*store*` is a special variable, a `let` gives you a scratch store that disappears when the `let` exits and leaves the global store alone. This REPL session also shows a two-hop join, where `?y` links the two patterns:

```lisp
* (let ((*store* nil))
    (add-triple 'a :knows 'b)
    (add-triple 'b :knows 'c)
    (query-triples '((?x :knows ?y) (?y :knows ?z))))
(((?Z . C) (?Y . B) (?X . A)))
```

# A tiny vector store

File: `vector-store.lisp`

Embedding-based semantic search in its simplest form: a hash table of labeled vectors and cosine-similarity ranking.

Cosine similarity measures the angle between two vectors, ignoring their magnitudes:

```$
\mathrm{cosine}(a, b) = \frac{a \cdot b}{\lVert a \rVert \, \lVert b \rVert}
```

## The code

```lisp
;; sbcl --script vector-store.lisp (in-memory dense vector store)

(defun v-dot (a b)
  (unless (= (length a) (length b))
    (error "Vector lengths differ: ~d vs ~d" (length a) (length b)))
  (loop for x across a for y across b sum (* x y)))

(defun v-norm (a)
  (sqrt (v-dot a a)))

(defun v-cosine (a b)
  (let ((na (v-norm a)) (nb (v-norm b)))
    (if (or (zerop na) (zerop nb)) 0.0 (/ (v-dot a b) (* na nb)))))

(defun make-vector-store ()
  (make-hash-table :test 'equal))

(defun store-add (store id text vec)
  (setf (gethash id store) (list text (coerce vec 'vector))))

(defun store-search (store query-vec &optional (k 3))
  (let ((qv (coerce query-vec 'vector)))
    (subseq
     (sort (loop for id being the hash-keys of store
                   using (hash-value item)
                 for score = (v-cosine qv (second item))
                 collect (list score id (first item)))
           #'> :key #'car)
     0 (min k (hash-table-count store)))))

;; Demo: Semantic vector search in 4D concept space
(let ((store (make-vector-store)))
  (store-add store "item-1" "queen"    #(0.90 0.90 0.05 0.10))
  (store-add store "item-2" "king"     #(0.95 0.10 0.05 0.10))
  (store-add store "item-3" "princess" #(0.80 0.95 0.05 0.15))
  (store-add store "item-4" "apple"    #(0.05 0.10 0.95 0.30))
  (store-add store "item-5" "banana"   #(0.05 0.10 0.90 0.95))

  (format t "Vector Store Entries: ~a~%" (hash-table-count store))

  (format t "~%Query 1: Royal female concept #(0.85 0.85 0.05 0.10)~%")
  (dolist (hit (store-search store #(0.85 0.85 0.05 0.10) 3))
    (format t "  [sim: ~5,3f] (~a) ~s~%"
            (first hit) (second hit) (third hit)))

  (format t "~%Query 2: Sweet fruit concept #(0.05 0.10 0.85 0.90)~%")
  (dolist (hit (store-search store #(0.05 0.10 0.85 0.90) 3))
    (format t "  [sim: ~5,3f] (~a) ~s~%"
            (first hit) (second hit) (third hit))))
```

## How it works

- `v-dot` steps through two vectors together with `loop ... across`, and `v-norm` reuses it for the Euclidean norm `\lVert a \rVert = \sqrt{a \cdot a}`$. A `loop` with two `across` clauses stops at the shorter vector without warning, so `v-dot` first checks that the lengths match. Mixing vectors from two embedding models is a common mistake, and an error beats a plausible but wrong score.
- `v-cosine` guards against division by zero: it defines a zero vector's similarity with anything as `0.0`.
- The store maps `id` to `(text vector)` in an `equal` hash table, so string IDs work. `store-add` coerces lists to vectors, so callers can pass either.
- `store-search` scores every entry, sorts in descending order, and returns the top `k`$ as `(score id text)` lists. `min` keeps `subseq` in bounds when the store holds fewer than `k`$ items.

## Running it

```bash
$ sbcl --script vector-store.lisp
```

Actual output:

```text
Vector Store Entries: 5

Query 1: Royal female concept #(0.85 0.85 0.05 0.10)
  [sim: 1.000] (item-1) "queen"
  [sim: 0.996] (item-3) "princess"
  [sim: 0.779] (item-2) "king"

Query 2: Sweet fruit concept #(0.05 0.10 0.85 0.90)
  [sim: 1.000] (item-5) "banana"
  [sim: 0.875] (item-4) "apple"
  [sim: 0.201] (item-3) "princess"
```

The demo uses hand-made 4D vectors whose axes roughly encode royalty, femininity, fruitiness, and sweetness. Query 1 (high royalty, female) ranks "queen" and "princess" above "king". Query 2 (a sweet fruit) ranks both fruits above the rest, and the sweetness axis puts the banana (0.95) well ahead of the apple (0.30).

## Using it

Replace the toy vectors with real embeddings from an API (Gemini and Ollama both offer embedding endpoints) and this code becomes a semantic search engine over your documents: split text into chunks, embed each chunk, `store-add` it, then `store-search` with the embedded question. Brute-force scoring handles thousands of vectors; beyond that, use an approximate-nearest-neighbor index. The interface here (add, search top-`k`$) matches what those indexes offer.

# Extractive text summarization

File: `summarizer.lisp`

A classic method from before neural networks: score each sentence by the average frequency of its significant words, keep the top few, and print them in their original order.

```$
\mathrm{score}(s) = \frac{1}{|s|} \sum_{w \in s} \mathrm{freq}(w)
```

where `\mathrm{freq}(w)`$ counts occurrences of word `w`$ across the whole document. Words on a short stop-word list get a frequency of zero, but they still count toward the sentence length `|s|`$, so filler words lower a sentence's score.

## The code

```lisp
;; sbcl --script summarizer.lisp (extractive text summarization)

(defparameter *stop-words*
  '("the" "a" "an" "in" "on" "at" "to" "for" "of" "and" "or" "is"
    "are" "was" "were" "it" "that" "this" "with" "as" "by" "from"
    "be" "has" "have" "its"))

(defun words (text)
  (loop with len = (length text) and acc = nil and res = nil
        for i from 0 below len
        for ch = (char text i)
        do (if (alphanumericp ch)
               (push (char-downcase ch) acc)
               (when acc
                 (push (coerce (nreverse acc) 'string) res)
                 (setf acc nil)))
        finally (when acc (push (coerce (nreverse acc) 'string) res))
                (return (nreverse res))))

(defun split-sentences (text)
  (loop with len = (length text) and start = 0 and res = nil
        for i from 0 below len
        for ch = (char text i)
        when (member ch '(#\. #\! #\?))
          do (let ((s (string-trim '(#\Space #\Tab #\Newline #\Return)
                                   (subseq text start (1+ i)))))
               (when (> (length s) 0) (push s res))
               (setf start (1+ i)))
        finally (let ((s (string-trim
                          '(#\Space #\Tab #\Newline #\Return)
                          (subseq text start len))))
                  (when (> (length s) 0) (push s res)))
                (return (nreverse res))))

(defun summarize (text &optional (n 2))
  (let* ((sentences (split-sentences text))
         (freqs (make-hash-table :test 'equal)))
    (dolist (s sentences)
      (dolist (w (words s))
        (unless (member w *stop-words* :test #'string=)
          (incf (gethash w freqs 0)))))
    (let ((scored
            (loop for s in sentences for idx from 0
                  for ws = (words s)
                  for score = (if (null ws) 0.0
                                  (/ (loop for w in ws
                                           sum (gethash w freqs 0))
                                     (float (length ws))))
                  collect (list score idx s))))
      (mapcar #'third
              (sort (subseq (stable-sort scored #'> :key #'first)
                            0 (min n (length scored)))
                    #'< :key #'second)))))

;; Demo: Multi-sentence paragraph extraction
(let* ((text
        (concatenate
         'string
         "Common Lisp is an expressive, multi-paradigm programming "
         "language with a rich history in artificial intelligence. "
         "It features dynamic typing, an advanced object system, "
         "and syntactic macros that allow programmers to create "
         "domain-specific languages. "
         "Extractive summarization algorithms score sentences based "
         "on significant word frequencies across a document. "
         "In this example, we calculate term frequencies and rank "
         "sentences to produce a concise summary. "
         "Common Lisp continues to empower developers to build "
         "complex symbolic and numerical systems with high "
         "productivity."))
       (summary (summarize text 2)))
  (format t "Original text: ~a sentences.~%~%"
          (length (split-sentences text)))
  (format t "Extractive 2-Sentence Summary:~%")
  (dolist (s summary)
    (format t "  • ~a~%" s)))
```

## How it works

- `words` and `split-sentences` use the same hand-written scanner pattern as the BM25 chapter: `loop` over characters, collect them, and emit at boundaries. Sentences end at `.`, `!`, or `?`. (`words` copies BM25's `tokenize`; six duplicated lines keep every file in this book self-contained.)
- An `equal` hash table counts word frequencies and skips `*stop-words*`, so common function words do not dominate the scores.
- A sentence's score is the *average* of its word frequencies; dividing by sentence length stops long sentences from winning just by having more words.
- The last expression needs care: sort by score in descending order, take the top `n` with `subseq`, then `sort` *again* by sentence index in ascending order. The second sort restores document order so the summary reads naturally. The first sort is a `stable-sort`: plain `sort` may reorder equal elements arbitrarily, so with ties at the cutoff the chosen sentences could differ between Lisp implementations. `stable-sort` keeps tied sentences in document order, so earlier sentences win ties.
- `summarize` never changes its input; the `(score idx s)` lists carry each sentence's index through both sorts.

## Running it

```bash
$ sbcl --script summarizer.lisp
```

Actual output:

```text
Original text: 5 sentences.

Extractive 2-Sentence Summary:
  • Extractive summarization algorithms score sentences based on significant word frequencies across a document.
  • Common Lisp continues to empower developers to build complex symbolic and numerical systems with high productivity.
```

## Using it

Pass it the output of the web-scraping chapter: `(summarize (page-text url) 3)` summarizes the web page at `url` without any AI service. It also works as a first pass before an LLM: pick the top sentences locally, then ask Gemini or Ollama to rewrite just those. Adjust `*stop-words*` for your domain, and treat the sentence splitter as a heuristic (abbreviations like "Dr." fool it).

# Symbolic polynomial math

File: `symbolic-math.lisp`

A small computer-algebra system: polynomials as association lists, exact rational arithmetic (addition, subtraction, multiplication), derivatives, integrals, and definite integrals by the fundamental theorem of calculus.

The program stores a polynomial as a sorted alist of `(exponent . coefficient)` pairs with like terms combined and zeros dropped, so `3x^2 - x + 5`$ is `((2 . 3) (1 . -1) (0 . 5))`. The calculus is the power rule in both directions:

```$
\frac{d}{dx} x^n = n\, x^{n-1}, \qquad \int x^n\, dx = \frac{x^{n+1}}{n+1}
```

and a definite integral evaluates the antiderivative at the endpoints:

```$
\int_a^b p(x)\, dx = F(b) - F(a)
```

## The code

```lisp
;; sbcl --script symbolic-math.lisp   (symbolic polynomial calculus)
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
(defun p* (p q)                         ; every term times every term
  (normalize (loop for (e1 . c1) in p
                   append (loop for (e2 . c2) in q
                                collect (cons (+ e1 e2) (* c1 c2))))))
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

(defun bound (b)                        ; rationals stay exact
  (case b
    (:pi pi)
    (:e (exp 1d0))
    (t (if (rationalp b) b (float b 1d0)))))

(defun definite (p a b)
  (let ((f (integ p)))
    (- (evaluate f (bound b)) (evaluate f (bound a)))))

(defun critical-point-p (p x &optional (tol 1d-9))
  (< (abs (evaluate (deriv p) x)) tol))

;;; Display
(defun term->string (e c v)             ; magnitude only: 3x^2, x, 5
  (let ((m (abs c)))
    (format nil "~:[~a~;~*~]~@[~(~a~)~]~@[^~a~]"
            (and (= m 1) (> e 0)) m     ; hide a coefficient of 1
            (and (> e 0) v)
            (and (> e 1) e))))

(defun ->string (p &optional (v 'x))
  (if (null p) "0"
      (with-output-to-string (out)
        (loop for (e . c) in p
              for first = t then nil
              do (write-string (cond ((not first)
                                      (if (minusp c) " - " " + "))
                                     ((minusp c) "-")
                                     (t ""))
                               out)
                 (write-string (term->string e c v) out)))))

(defun integral->string (p &optional a b (v 'x))
  (flet ((show (limit) (case limit (:pi "π") (:e "e") (t limit))))
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
  (format t "p * q      : ~a~%" (->string (p* p q)))
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
```

## How it works

- `normalize` keeps polynomials in canonical form: it sums coefficients per exponent in a hash table, drops zero coefficients, and sorts by descending exponent. Every constructor and arithmetic function calls it.
- `poly` builds a polynomial from coefficients highest-degree first: `(poly 3 -1 5)` means `3x^2 - x + 5`$.
- `p*` multiplies every term of one polynomial by every term of the other (add exponents, multiply coefficients) and lets `normalize` combine like terms. The canonical form keeps multiplication down to three lines.
- Coefficients are ordinary Lisp numbers, so ratios stay exact. The antiderivative of `3x^2`$ has coefficient `3/3 = 1`$, but the antiderivative of `-x`$ carries the rational `-\frac{1}{2}`$.
- `deriv` and `integ` take an optional repeat count: `(deriv p 3)` is the third derivative, computed by recursing on the single-step rule. The `unless (zerop e)` clause drops the constant term under `deriv`.
- `bound` accepts integration bounds as numbers or the keywords `:pi` and `:e`. Rational bounds (integers and ratios) stay exact, so `(definite p 0 1)` returns the exact rational `11/2`; only `:pi`, `:e`, and float bounds produce a double float.
- `critical-point-p` checks whether `p'(x) = 0`$ within a tolerance. For our quadratic, `p'(x) = 6x - 1 = 0`$ at `x = 1/6`$, and since `1/6` is an exact rational, the derivative evaluates to exactly zero.
- `->string` prints polynomials the way people write them: `3x^2 - x + 5`, not `3x^2 + -1x + 5`. `term->string` prints one term's *magnitude* and hides a coefficient of 1 on non-constant terms; `->string` adds the signs: a leading `-` for a negative first term, then ` + ` or ` - ` between terms. The `format` directive `~:[...~;...~]` picks one of two clauses based on a boolean, and `~@[...~]` prints a group only when its argument is non-nil, which is how the variable and exponent appear only when needed.

## Running it

```bash
$ sbcl --script symbolic-math.lisp
```

Actual output:

```text
p          : 3x^2 - x + 5
p + q      : 3x^2 + 7
p - q      : 3x^2 - 2x + 3
p * q      : 3x^3 + 5x^2 + 3x + 10
2p         : 6x^2 - 2x + 10
degree, p(2): 2, 15
p', p'', p''': 6x - 1 | 6 | 0
∫p, ∫∫p    : x^3 - 1/2x^2 + 5x | 1/4x^4 - 1/6x^3 + 5/2x^2
∫[0,1](3x^2 - x + 5) dx = 11/2
∫[0,π](3x^2 - x + 5) dx = 41.7794
x=1/6 critical? T  x=0? NIL
```

Check the ninth line against the symbolic answer:

```$
\int_0^1 (3x^2 - x + 5)\, dx = \left[ x^3 - \frac{1}{2} x^2 + 5x \right]_0^1 = 1 - \frac{1}{2} + 5 = \frac{11}{2}
```

The program agrees exactly: `11/2` is a Lisp ratio, not a rounded `5.5`. Arithmetic stays rational from the antiderivative (`-1/2x^2`, `5/2x^2` in the output) to the answer. Only the integral up to `:pi` needs floating point, because `\pi`$ is irrational.

## Using it

Use it to check calculus homework, generate exact examples for teaching, or as the symbolic core of a larger system. Natural extensions: polynomial long division (which pairs well with `p*`), composition `p(q(x))`$ built from `p*` and `p+`, rational functions as pairs of polynomials, or a `solve` for quadratic roots. The choice of representation (canonical alists) keeps every operation short, and it deserves as much study as the calculus.

# Scalar automatic differentiation

File: `autograd.lisp`

The core algorithm of every neural-network library, in about sixty lines: build a computation graph of scalar operations, then traverse it in reverse, accumulating gradients with the chain rule.

Each node records its value, its parents, and a closure that computes the *local* gradient of its operation. Reverse-mode differentiation sets the output's gradient to `1`$ and propagates backward: for `c = a \cdot b`$ the local rules are `\partial c / \partial a = b`$ and `\partial c / \partial b = a`$; for addition both partials are `1`$; for `\mathrm{relu}`$ the gradient passes only where the output is positive.

## The code

```lisp
;; sbcl --script autograd.lisp   (scalar automatic differentiation DAG)

(defstruct (val (:constructor %val (data &optional prev op backward)))
  data (grad 0.0) prev op backward)

(defun val (d) (if (val-p d) d (%val (float d 1.0))))

(defun v+ (a b)
  (let* ((a (val a))
         (b (val b))
         (out (%val (+ (val-data a) (val-data b)) (list a b) '+)))
    (setf (val-backward out)
          (lambda ()
            (incf (val-grad a) (val-grad out))
            (incf (val-grad b) (val-grad out))))
    out))

(defun v* (a b)
  (let* ((a (val a))
         (b (val b))
         (out (%val (* (val-data a) (val-data b)) (list a b) '*)))
    (setf (val-backward out)
          (lambda ()
            (incf (val-grad a) (* (val-data b) (val-grad out)))
            (incf (val-grad b) (* (val-data a) (val-grad out)))))
    out))

(defun v-relu (a)
  (let* ((a (val a))
         (out (%val (max 0.0 (val-data a)) (list a) 'relu)))
    (setf (val-backward out)
          (lambda ()
            (incf (val-grad a)
                  (if (> (val-data out) 0.0) (val-grad out) 0.0))))
    out))

(defun backward (root)
  (let ((topo nil) (visited (make-hash-table :test 'eq)))
    (labels ((build (v)
               (unless (gethash v visited)
                  (setf (gethash v visited) t)
                  (dolist (p (val-prev v)) (build p))
                  (push v topo))))
      (build root))
    (setf (val-grad root) 1.0)
    (dolist (v topo)
      (when (val-backward v) (funcall (val-backward v))))))

;; Demo: d = (a * b) + c,  e = relu(d)
(let* ((a (val 2.0))
       (b (val -3.0))
       (c (val 10.0))
       (d (v+ (v* a b) c))
       (e (v-relu d)))
  (backward e)
  (format t "Forward:  d = (a * b) + c = (~a * ~a) + ~a = ~a~%"
          (val-data a) (val-data b) (val-data c) (val-data d))
  (format t "          e = relu(d) = ~a~%" (val-data e))
  (format t "Gradients after (backward e):~%")
  (format t "  de/de = ~4,2f~%" (val-grad e))
  (format t "  de/dd = ~4,2f~%" (val-grad d))
  (format t "  de/dc = ~4,2f  (expected 1.0)~%" (val-grad c))
  (format t "  de/da = ~4,2f  (expected b = -3.0)~%" (val-grad a))
  (format t "  de/db = ~4,2f  (expected a = 2.0)~%" (val-grad b)))
```

## How it works

- `defstruct` with a renamed internal constructor `%val` is a common Lisp pattern: the public function `val` then acts as a smart constructor that coerces numbers to floats and returns existing nodes unchanged. That lets `v+` accept `(v+ 2 x)` as easily as `(v+ x y)`.
- Each operation builds its output node, then installs a `backward` closure that captures the inputs. The closure *adds* (`incf`) to parent gradients rather than assigning them, which correctness requires when a value appears in the graph more than once: `(v* x x)` must give `x` a gradient of `2x`, one term from each use.
- `backward` sorts the graph topologically with a depth-first search (`labels` defines the local recursive `build`; an `eq` hash table tracks visited nodes), sets the root's gradient to `1.0`, and runs the closures in reverse topological order (root first), so each node's gradient is final before its own closure runs.
- `op` exists only for inspection and debugging; the closures do all the computation.

## Running it

```bash
$ sbcl --script autograd.lisp
```

Actual output:

```text
Forward:  d = (a * b) + c = (2.0 * -3.0) + 10.0 = 4.0
          e = relu(d) = 4.0
Gradients after (backward e):
  de/de = 1.00
  de/dd = 1.00
  de/dc = 1.00  (expected 1.0)
  de/da = -3.00  (expected b = -3.0)
  de/db = 2.00  (expected a = 2.0)
```

By hand, the forward pass is:

```$
\begin{aligned}
d &= a \cdot b + c = (2)(-3) + 10 = 4 \\
e &= \mathrm{relu}(d) = \max(0, 4) = 4
\end{aligned}
```

and since `e = d`$ here (the relu is in its linear region), the chain rule gives:

```$
\begin{aligned}
\frac{\partial e}{\partial d} &= 1, &
\frac{\partial e}{\partial c} &= 1 \\
\frac{\partial e}{\partial a} &= b = -3, &
\frac{\partial e}{\partial b} &= a = 2
\end{aligned}
```

This matches the program's output exactly.

## Using it

This is Andrej Karpathy's *micrograd* idea, ported to Lisp. To turn it into a trainable neuron: add `v-tanh` or `v-exp` (each needs only its local gradient), build a dot product from `v*` and `v+`, and write a training loop that calls `backward` on a loss node and moves each leaf value by `-lr * grad`. One caveat: gradients accumulate in `val-grad`, so reset them to zero between training steps with a one-line `zero-grad` loop over the topo list.

{appendix}

# Loading every example into one REPL

File: `load.lisp`

Fifteen of the sixteen example programs end with demo calls (`osascript.lisp` keeps its examples in comments, and `load.lisp` is the seventeenth file). Demos help when you run a script but get in the way when you want every definition in one REPL. `load.lisp` reads each file form by form and `eval`s only the definition forms.

## The code

```lisp
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
                                  '(defun defmacro defstruct defclass
                                    defgeneric defmethod defvar
                                    defparameter defconstant defpackage
                                    in-package require load
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
    ("(dom url-or-dom)"
     "fetch a URL, or pass a parsed DOM through")
    ("search.lisp")
    ("(esearch \"query\" [n])"
     "Exa search -> (title url text)")
    ("(bsearch \"query\" [n])"
     "Brave search -> (title url text)")
    ("(curl-json &rest curl-args)"
     "run curl, parse JSON reply")
    ("(results items text-key)"
     "hits -> (title url text) lists")
    ("(api-key \"ENV_VAR\")"
     "read an env var or signal an error")
    ("(unescape string)"
     "decode common HTML entities")
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
    ("(p+ p q ...) (p- p q) (p* p q)"
     "add / subtract / multiply polynomials")
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
     "definite integral from a to b (exact for rationals)")
    ("(critical-point-p p 1/6)"
     "is p'(x) = 0 ?")
    ("(->string p)"
     "p as text: 3x^2 - x + 5")
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
    ("(match-triple pattern triple env)"
     "unify one pattern with one triple -> env or :fail")
    ("(var-p x)"
     "is x a ?variable symbol")
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
    ("(hopfield-recall w input [max-sweeps])"
     "recall until stable -> state, sweeps used")
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
```

## How it works

- The loader finds its own directory with `*load-truename*`, visits every `.lisp` file except itself, and reads forms with `(read s nil s)`, a classic idiom that uses the stream itself as the end-of-file marker.
- It evaluates only forms whose `car` is on the whitelist (`defun`, `defmacro`, `defstruct`, `defclass`, `defmethod`, `defvar`, `defparameter`, ...). The book's files use a few of these, but the full set keeps the loader working when you add your own files to the directory. It skips top-level demo calls, which is why each file can end in demos and still load as a library.
- Binding `*package*` to `cl-user` during reads makes symbols read the same way no matter which package the REPL is in.
- `*help*` is a data-driven catalog: one-element lists are section headers (file names), and two-element lists hold a call signature and a description.
- `help` prints everything, or only rows that match a filter string (case-insensitive, against both signature and description), and returns `(values)` (no value) to keep REPL output tidy.

## Running it

```lisp
* (load "load.lisp")
* (help "search")
  (esearch "query" [n])              ; Exa search -> (title url text)
  (bsearch "query" [n])              ; Brave search -> (title url text)
  (bm25-search corpus query)         ; Okapi BM25 ranked document retrieval
  (store-search store qvec [k])      ; top-K nearest neighbors by cosine similarity
```

The filter is a plain substring match, so `(help "search")` finds both the web-search APIs and the two local retrieval engines. `(help)` with no argument prints the whole catalog grouped by file.

## Using it

Load everything once, then mix the chapters in a single session. For example, rank documents with BM25 and summarize the hits, using two chapters with no extra code (real transcript):

```lisp
* (defparameter *corpus*
    '("Common Lisp is a general-purpose programming language with powerful macros."
      "Python is an interpreted language known for data science and machine learning."
      "Deep learning models require automatic differentiation and gradient optimization."))
*CORPUS*
* (summarize (format nil "~{~a ~}" (mapcar #'second (bm25-search *corpus* "learning"))) 1)
("Deep learning models require automatic differentiation and gradient optimization.")
```

Other one-liners to try: `(summarize (page-text url) 3)`, or `(backward e)` after you build a graph with `v+` and `v*`. The selective-`eval` trick works for your own script collections too: it turns a directory of runnable programs into a library without editing the files.
