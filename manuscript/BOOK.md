{frontmatter}

# Little Bits of Common Lisp

*Seventeen tiny programs: LLMs, the web, macOS automation, classic AI, and symbolic math — each in a single file*

**by Mark Watson**

# Preface

I have used Common Lisp professionally since 1982. The language remains fast, flexible, and stable for artificial intelligence, data processing, and symbolic computing.

This book collects small, complete programs. Each chapter provides one working example in a single file. You can read the chapters in any order. Pick the topics that interest you most and run the code.

For in-depth coverage and larger projects, see my book *Loving Common Lisp* at <https://leanpub.com/lovinglisp>. You can find my other books, software, and articles at <https://markwatson.com>.

I thank my wife Carol Watson for her support and editorial help.

{mainmatter}

# Introduction

This is a book of small, complete Common Lisp programs. Every chapter is one self-contained `.lisp` file — most are well under 100 lines — that you can read end to end in a few minutes and run immediately with `sbcl --script`. Nothing is elided: each chapter lists the entire program, explains how it works, shows what running it looks like, and suggests ways to use and extend it.

The examples are deliberately practical. They call large language models (Apple's on-device model, Google Gemini, local Ollama models), query web search APIs and SPARQL knowledge graphs, scrape and render web pages, automate macOS applications, and implement classic algorithms from scratch: Bayesian inference, BM25 document ranking, a Hopfield network, a triple store, a vector store, an extractive summarizer, symbolic polynomial calculus, and reverse-mode automatic differentiation.

A stylistic note: the network-facing examples shell out to `curl` (via `uiop:run-program`) instead of pulling in an HTTP client library. This keeps the dependency list short and makes each program easy to copy into your own projects.

## What you need

- **SBCL** — every program runs with `sbcl --script filename.lisp`.
- **Quicklisp** — needed by the Gemini, Ollama, search, SPARQL, and web-scraping examples.
- **curl** — used as the HTTP client by every network example.
- **API keys in environment variables** — `GOOGLE_API_KEY` for Gemini, `EXA_SEARCH_API_KEY` and `BRAVE_SEARCH_API_KEY` for the web search chapter.
- **Ollama** — a locally running Ollama server for the Ollama chapter.
- **Lightpanda** — the Lightpanda headless browser binary for that chapter.
- **macOS** — for the AppleScript automation and Apple Foundation Model chapters.

Every program begins with a comment showing exactly how to run it. The chapters are independent — read them in any order. If you would rather load every definition into one REPL session and experiment interactively, see the appendix on `load.lisp`.

## Which chapters run as-is

| Chapter | Needs beyond SBCL | Output in this book |
|---|---|---|
| Apple Foundation Models | macOS + Apple Intelligence + `fm` | Illustrative (needs `sudo fm license`) |
| Gemini | Quicklisp + `GOOGLE_API_KEY` | Real transcript |
| Ollama | Local `ollama serve` + pulled model | Real transcript |
| Web search (Exa, Brave) | Quicklisp + two API keys | Real transcript, abridged |
| SPARQL | Quicklisp | Real transcript |
| Lightpanda | `lightpanda` binary | Real transcript, abridged |
| Web scraping | Quicklisp | Real transcript, abridged |
| AppleScript automation | macOS (+ permissions per function) | One real line; rest are live-state calls |
| Bayes, BM25, Hopfield, triple store, vector store, summarizer, symbolic math, autograd | Nothing | Real transcript, verbatim |

The examples live in the `SHORTEST_CODE` directory of the author's `common-lisp-experiments` GitHub monorepo.

# On-Device AI with Apple Foundation Models

File: `apple-system-model.lisp`

Recent versions of macOS ship with Apple's on-device foundation model, exposed to scripts through the `fm` command-line tool. This nine-line program is the shortest LLM client in the book: no API key, no network, no bill.

## The Code

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

## How It Works

- `(require :asdf)` makes UIOP available; `uiop:run-program` is the workhorse used throughout this book to run external commands and capture their output.
- `apple-fm` runs `fm respond --no-stream <prompt>`, capturing standard output as a string with `:output :string`. The `--no-stream` flag makes `fm` print the whole reply at once instead of streaming tokens.
- `string-trim` removes the whitespace and newline that `fm` adds around the reply.

## Running It

You need macOS with Apple Intelligence enabled and the `fm` tool license accepted (`sudo fm license`). Then:

```bash
$ sbcl --script apple-system-model.lisp
```

The program prints the model's reply as a Lisp string:

```text
"1 + 10 is 11."
```

## Using It

Because the model runs entirely on your Mac, this is a good choice for prompts you do not want to leave the machine: summarizing private notes, classifying local documents, or glue intelligence inside shell-style Lisp scripts. The trade-offs are a small model with limited capability compared to hosted models, and no control over temperature or system prompts through this simple interface. For anything heavier, see the Gemini and Ollama chapters that follow.

# Calling Google Gemini

File: `gemini.lisp`

This program calls Google's Gemini API and parses the JSON reply, in eighteen lines including the demo call.

## The Code

```lisp
;; sbcl --script gemini.lisp   (needs Quicklisp + GOOGLE_API_KEY)
#-quicklisp (load "~/quicklisp/setup.lisp")
(ql:quickload :com.inuoe.jzon :silent t)

(defun gemini (prompt &optional (model "gemini-3.5-flash-lite"))
  (let* ((base
          "https://generativelanguage.googleapis.com/v1beta/models/")
         (url (format nil "~a~a:generateContent" base model))
         (key (uiop:getenv "GOOGLE_API_KEY"))
         (body (format nil
                       "{\"contents\":[{\"parts\":[{\"text\":~a}]}]}"
                       (com.inuoe.jzon:stringify prompt)))
         (j (com.inuoe.jzon:parse
             (uiop:run-program
              (list "curl" "-s" url
                    "-H" "Content-Type: application/json"
                    "-H" (format nil "x-goog-api-key: ~a" key)
                    "-d" body)
              :output :string))))
    (gethash "text"
             (aref (gethash "parts"
                            (gethash "content"
                                     (aref (gethash "candidates" j) 0)))
                   0))))

(print (gemini "what is 1 + 10?"))
```

## How It Works

- `#-quicklisp` reads as "if Quicklisp is not already loaded": when run as a script, load `~/quicklisp/setup.lisp` first. This idiom lets the same file work both as a script and inside a REPL that already has Quicklisp.
- `com.inuoe.jzon` is a fast, sane JSON library. `jzon:parse` turns JSON into hash tables and vectors; `jzon:stringify` turns a Lisp string into a properly escaped JSON string literal.
- The request body is built with `format`, using `jzon:stringify` to escape the prompt safely — embedding user text in JSON by hand is an injection bug waiting to happen, and the one-line `stringify` call prevents it.
- `curl -s` POSTs to the `generateContent` endpoint with the API key in the `x-goog-api-key` header, read from the environment with `uiop:getenv`.
- The reply is nested JSON: `candidates[0].content.parts[0].text`. The final expression walks that structure with `gethash` and `aref`.

## Running It

```bash
$ export GOOGLE_API_KEY=...   # from https://aistudio.google.com
$ sbcl --script gemini.lisp
```

Actual output (the exact wording varies from run to run, as with any language model):

```text
"1 + 10 = 11"
```

## Using It

Pass a second argument to switch models: `(gemini "summarize this file" "gemini-3.5-flash")`. The function composes well with the file-based examples later in the book — summarize the output of the web-scraping chapter, or answer questions about documents ranked by the BM25 chapter. Errors (a missing key, a rate limit) come back as JSON without a `candidates` field, so a production version should check for that before walking the hash tables.

# Local LLMs with Ollama

File: `ollama.lisp`

The same pattern as the Gemini chapter, but pointed at a model running on your own machine via Ollama's HTTP API.

## The Code

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
                       (com.inuoe.jzon:stringify prompt))))
    (gethash "response"
             (com.inuoe.jzon:parse
              (uiop:run-program
               (list "curl" "-s"
                     "http://localhost:11434/api/generate"
                     "-d" body)
               :output :string)))))

(print (ollama "what is 1 + 10?"))
```

## How It Works

- Ollama serves a local HTTP API on port 11434. The `/api/generate` endpoint takes a model name and a prompt.
- `"stream":false` asks for the complete reply in one JSON document instead of a stream of token fragments — much easier to handle with a single `jzon:parse`.
- `"think":false` disables the reasoning trace on models that support it (like the Qwen 3 family), so the `response` field contains just the answer.
- The reply's `response` key holds the generated text, which is all this program returns.

## Running It

Install Ollama, pull the model (`ollama pull qwen3.5:4b`), make sure the server is running, then:

```bash
$ sbcl --script ollama.lisp
```

Actual output (the exact wording varies from run to run):

```text
"The result of $1 + 10$ is **11**."
```

## Using It

Local models are private, free per call, and work offline — ideal for batch jobs over local documents (pair this with the summarizer or vector-store chapters). Swap the model name to use anything you have pulled: `(ollama "hi" "llama3.2")`. Latency depends on your hardware; small 4B-class models are comfortable on a laptop.

# Web Search with Exa and Brave

File: `search.lisp`

Two search-engine APIs, one calling convention: both `esearch` and `bsearch` take a query string and return a list of `(title url text)` triples.

## The Code

```lisp
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
```

## How It Works

- `curl-json` is a tiny but genuinely reusable helper: run `curl -s` with any argument list, parse the reply as JSON. `list*` prepends `"curl" "-s"` to whatever arguments the caller supplies.
- `results` normalizes both APIs into the same shape. The two engines differ in one detail — Exa's page content comes back under the key `text`, Brave's snippet under `description` — so the text key is a parameter.
- `esearch` POSTs JSON, asking Exa to include up to 300 characters of page text per hit.
- `bsearch` uses `curl -G` with `--data-urlencode` for a properly URL-encoded GET request — the right tool when parameters go in the query string rather than a JSON body.

## Running It

```bash
$ export EXA_SEARCH_API_KEY=...
$ export BRAVE_SEARCH_API_KEY=...
$ sbcl --script search.lisp
```

The program prints two lists, one per engine; each element is a `(title url text)` list. Actual output (with long README metadata lines in the Exa text snippets trimmed for brevity):

```text
(("mmontone/cl-sparql" "https://github.com/mmontone/cl-sparql"
  "# mmontone/cl-sparql
SPARQL query builder for Common Lisp
- Stars: 12
- License: MIT License ...")
 ("mark-watson/sparql" "https://github.com/mark-watson/sparql"
  "# Repository: mark-watson/sparql
Common Lisp SPARQL client code - see book \"Loving Common Lisp,
or the Savvy Programmer's Secret Weapon\"
- Primary language: Common Lisp ...")
 ("madnificent/cl-fuseki" "https://github.com/madnificent/cl-fuseki"
  "# madnificent/cl-fuseki
Common Lisp library for connecting to SPARQL endpoints.
- License: MIT License ..."))

(("The Best Hikes in Sedona, Arizona | A Hiking Travel Guide"
  "https://zannavandijk.co.uk/the-best-hikes-in-sedona/"
  "This is a relatively easy hike with non-stop views of iconic Sedona
rock formations. The trail starts as a loop around the butte and then
you have the option of adding on the climb up Bell Rock which I highly
recommend, the views are incredible!")
 ("10 Best Hikes in Sedona AZ to do For First Time Visitors"
  "https://thenatureseeker.com/best-hikes-in-sedona-az-the-top-10-trails-to-check-out/"
  "This is one of my favorite hiking trails in Sedona. You'll be
walking on a relatively easy trail with slight inclines and declines
for 2 miles before venturing off into a more remote hike that takes
you to the famous Soldiers Pass Caves.")
 ("The Best Hikes in Sedona, Arizona (Plus Tips on Parking & More)"
  "https://www.lostwithlydia.com/destinations/usa/az/Best-Day-Hikes-in-Sedona/"
  "Another option is to take the Baldwin Trail or Templeton Trail and
connect over to the <strong>Cathedral Rock Trail</strong>. The Baldwin
Trailhead is a 20 minute drive from the <strong>Cathedral Rock
Trail</strong>head and has about 40 parking spots."))
```

## Using It

These two functions are building blocks for retrieval-augmented generation: search, then stuff the `(title url text)` triples into a prompt for the Gemini or Ollama chapters. Exa is a semantic/neural search engine and tends to find topically related pages even without keyword overlap; Brave is a classic keyword index with independent coverage of the web. Running both and merging results is a cheap way to improve recall.

# Querying Knowledge Graphs with SPARQL

File: `sparql.lisp`

DBpedia and Wikidata are enormous public knowledge graphs, and both answer SPARQL queries over HTTP. This program turns a query string into a list of Lisp association lists.

## The Code

```lisp
;; sbcl --script sparql.lisp   (needs Quicklisp + curl)
#-quicklisp (load "~/quicklisp/setup.lisp")
(ql:quickload :com.inuoe.jzon :silent t)

(defun sparql (endpoint query)
  "Returns a list of rows, each row an alist of (variable . value)."
  (let* ((cmd (list "curl" "-s" "-G" endpoint
                    "-H" "Accept: application/sparql-results+json"
                    "-A" "sparql.lisp/1.0 (Common Lisp example)"
                    "--data-urlencode"
                    (concatenate 'string "query=" query)))
         (raw (uiop:run-program cmd :output :string))
         (json (com.inuoe.jzon:parse raw))
         (bindings (gethash "bindings" (gethash "results" json))))
    (map 'list
         (lambda (row)
           (loop for var being the hash-keys of row
                 using (hash-value b)
                 collect (cons var (gethash "value" b))))
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

## How It Works

- The request is a GET with the query URL-encoded via `--data-urlencode`, and an `Accept` header asking for the standard JSON results format. A descriptive `User-Agent` (`-A`) is good manners — and some endpoints, Wikidata in particular, ask for one.
- In the JSON results format, each solution is an object mapping variable names to binding objects; the binding's `value` key holds the lexical form. The inner `loop` flattens that into the Lisp-native `(variable . value)` alist shape.
- `dbpedia` and `wikidata` are one-line specializations of `sparql` for the two endpoints.

## Running It

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

## Using It

Structured knowledge graphs complement the statistical text sources in the rest of this book: SPARQL gives you precise, citable facts rather than snippets. Try asking DBpedia for the abstract of a topic (`dbo:abstract`), or use Wikidata's `wdt:` property paths to walk relationships. The triple-store chapter later in the book implements a miniature version of this same idea — pattern matching with variables — over in-memory data.

# JavaScript-Rendered Pages with Lightpanda

File: `lightpanda.lisp`

Some pages barely exist until JavaScript runs. Lightpanda is a lightweight headless browser built for exactly this case; here Lisp drives it as a subprocess.

## The Code

```lisp
;; sbcl --script lightpanda.lisp   (needs the lightpanda binary on PATH)
(require :asdf)

(defun lightpanda (url &optional (dump "html"))
  "DUMP is one of: html, markdown, semantic_tree, semantic_tree_text."
  (uiop:run-program
   (list "lightpanda" "fetch" "--dump" dump
         "--log_level" "warn" url)
   :output :string))

(defun links (html)
  (loop for i = (search "href=\"" html)
        then (search "href=\"" html :start2 end)
        for end = (and i (position #\" html :start (+ i 6)))
        while end collect (subseq html (+ i 6) end)))

(print (lightpanda "https://markwatson.com/" "markdown"))
(print (links (lightpanda "https://markwatson.com/")))
```

## How It Works

- `lightpanda fetch` renders the page (JavaScript included) and dumps it in one of four formats: raw `html`, a `markdown` conversion, or the `semantic_tree` variants that expose the page's structure. `--log_level warn` keeps diagnostics off standard output so the return value is clean.
- `links` is a deliberately simple string scan, not an HTML parser: `search` finds each `href="` marker and `position` finds the closing quote. For well-formed output from a renderer this is fine; for arbitrary wild HTML, use the real parser in the web-scraping chapter instead.

## Running It

Install Lightpanda so the `lightpanda` binary is on your `PATH`, then:

```bash
$ sbcl --script lightpanda.lisp
```

The first `print` shows the home page rendered as a Markdown string (headings, links, and text with the markup stripped). Actual output, abridged:

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

The second prints a list of the page's href strings — actual output, abridged:

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

## Using It

The `markdown` dump is the interesting one for AI pipelines: it converts a JavaScript-heavy page into compact text you can feed straight to a model from the Gemini or Ollama chapters. The author's separate `lightpanda` project in the same monorepo wraps the browser's full Chrome DevTools Protocol interface (clicking, typing, screenshots); this chapter is the eighty-twenty version.

# Web Scraping with Plump

File: `webscraping.lisp`

When a page is plain HTML, you do not need a browser at all: fetch with `curl`, parse into a real DOM with Plump, and walk the tree.

## The Code

```lisp
;; sbcl --script webscraping.lisp   (needs Quicklisp + curl)
#-quicklisp (load "~/quicklisp/setup.lisp")
(ql:quickload '(:plump :clss :cl-ppcre) :silent t)

(defun fetch (url)
  (plump:parse
   (uiop:run-program
    (list "curl" "-sL" "-A" "Mozilla/5.0" url) :output :string)))

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

(defun headers (url)
  (map 'list (lambda (h) (clean (text h)))
       (clss:select "h1,h2,h3,h4,h5,h6" (fetch url))))

(defun page-text (url) (clean (text (fetch url))))

(print (headers "https://markwatson.com"))
(format t "~%~%~a~%" (page-text "https://markwatson.com"))
```

## How It Works

- Three libraries do the heavy lifting: `plump` parses HTML into a DOM, `clss` adds CSS-selector queries over that DOM, and `cl-ppcre` provides regular expressions for whitespace cleanup.
- `fetch` runs `curl -sL` (following redirects) with a browser-like `User-Agent`, and parses the reply.
- `text` is the heart of the program: a recursive DOM walk that skips boilerplate elements (`script`, `style`, `nav`, `header`, `footer`, ...), collapses whitespace inside text nodes, and turns block-level tags into newlines so the output keeps the page's visual paragraph structure.
- `clean` post-processes: strip leading/trailing spaces on each line, collapse runs of three or more newlines into a single blank line, trim the ends.
- `headers` shows off `clss`: one CSS selector grabs all `h1`–`h6` elements.

## Running It

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

## Using It

`page-text` is a good front end for the summarizer chapter: summarize any web page with `(summarize (page-text url) 3)`. `headers` alone is handy for skimming a page's structure. The trade-off versus the Lightpanda chapter: this approach is faster and has no external binary dependency, but it never runs JavaScript — pick per page.

# Automating macOS with AppleScript

File: `osascript.lisp`

macOS exposes Mail, Calendar, Reminders, Messages, and Safari to AppleScript — and `osascript` runs AppleScript from the command line. From Lisp, that means every one of those apps is one `uiop:run-program` call away.

## The Code

```lisp
;;;; osascript.lisp -- tiny macOS automation via osascript.
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
    (if (zerop code)
        (string-trim '(#\Space #\Newline) out)
        (error "osascript: ~a" err))))

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

## How It Works

- `osascript` (the Lisp function) captures stdout, stderr, and the exit code separately via `multiple-value-bind`; a non-zero exit signals a Lisp error carrying AppleScript's own error message.
- The `~S` format directive is the elegant trick in this file: it prints a Lisp string as a quoted, escaped string literal, which is *also* valid AppleScript (and JavaScript) syntax. That makes string interpolation into scripts safe and readable.
- `get-todays-events` shows a real AppleScript pattern: build a list, set `text item delimiters` to a separator, return it as a string, then split on the Lisp side with `uiop:split-string`.
- `read-recent-imessages` bypasses AppleScript entirely and queries Messages' SQLite database directly with `sqlite3 -json` — which is why it needs Full Disk Access. `check-type` guards the `limit` parameter that gets spliced into SQL.
- `safari-login` opens a page, polls `document.readyState` every half second until the page loads (or errors after `timeout` seconds), then runs JavaScript that fills the username/password fields and submits the form.

## Running It

Load the file in a REPL rather than as a script, since the examples at the bottom are commented out. You will need to grant your terminal Automation permission (macOS will prompt the first time), Full Disk Access for `read-recent-imessages`, and enable *Safari → Develop → Allow JavaScript from Apple Events* for `safari-login`.

```lisp
* (load "osascript.lisp")
* (osascript "return 1 + 10")
"11"
```

The `"11"` above is real output, verified by running it. The remaining functions are shown as calls rather than transcripts because their results depend on your machine's live state (inbox count, today's calendar) or change it (sending a message, adding a reminder) — try them in your own REPL.

## Using It

This chapter is a template more than a toolkit: any AppleScript you find online can be wrapped in the same way. Keep credentials in environment variables (as the final example shows) rather than in source. Combining these functions with an LLM chapter is fertile ground: summarize today's calendar, get notified in iMessage when a script finishes, or check in on your Leanpub royalties automatically.

# Bayesian Inference

File: `bayes.lisp`

Twenty lines of Lisp implement Bayes' theorem as a reusable update function, and the demo reproduces the famous medical "base-rate fallacy" result.

Bayes' theorem computes the posterior probability of a hypothesis given evidence:

```$
P(H \mid E) = \frac{P(E \mid H) \, P(H)}{P(E)}
```

The program works with whole distributions at once: a distribution is an alist of `(hypothesis . probability)` pairs, and the denominator `P(E)`$ is handled implicitly by normalizing after the update.

## The Code

```lisp
;; sbcl --script bayes.lisp (Bayesian inference)

(defun bayes-normalize (dist)
  (let ((sum (reduce #'+ dist :key #'cdr)))
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

## How It Works

- `bayes-update` multiplies each prior probability by the likelihood of the evidence under that hypothesis, then `bayes-normalize` divides through by the total so the probabilities sum to one again. That product-then-normalize pair *is* Bayes' theorem.
- The likelihood is passed in as a function, so the same updater works for any hypothesis/evidence types.
- `map-hypothesis` returns the most probable pair — the maximum a posteriori (MAP) estimate.
- `reduce` with `:key #'cdr` sums probabilities without a loop; the `~{...~^, ~}` format directive prints the alist as a comma-separated table.

## Running It

```bash
$ sbcl --script bayes.lisp
```

Actual output:

```text
Prior:         HAS-DISEASE: 0.0100, HEALTHY: 0.9900
After 1st (+): HAS-DISEASE: 0.1610, HEALTHY: 0.8390  -> MAP: HEALTHY
After 2nd (+): HAS-DISEASE: 0.7848, HEALTHY: 0.2152  -> MAP: HAS-DISEASE
```

The first line is the fallacy made concrete: even with a positive result from a "95% accurate" test, a patient with a 1%-prevalence disease probably does *not* have it — the posterior is only about 16%:

```$
P(D \mid +) = \frac{0.95 \cdot 0.01}{0.95 \cdot 0.01 + 0.05 \cdot 0.99} \approx 0.161
```

Feeding the posterior back in as the new prior for a second independent positive test (`post2`) raises the probability to about 78%.

## Using It

Swap in your own hypotheses and likelihoods: spam classification, sensor fusion, diagnosis with more than two hypotheses. The one caveat is the independence assumption — sequential `bayes-update` calls treat each piece of evidence as conditionally independent given the hypothesis, so correlated evidence (say, the same test run twice) will overconfidently multiply.

# Ranking Documents with BM25

File: `bm25.lisp`

BM25 is the ranking function inside generations of search engines. This program implements it from scratch in about thirty lines: tokenize a tiny corpus, score documents against a query, return ranked hits.

For term `t`$ occurring in `n_t`$ of `N`$ documents, the inverse document frequency is:

```$
\mathrm{idf}(t) = \ln\!\left(1 + \frac{N - n_t + 0.5}{n_t + 0.5}\right)
```

and the score of document `d`$ for query `q`$ is:

```$
\mathrm{score}(d, q) = \sum_{t \in q} \mathrm{idf}(t)\; \frac{f(t,d)\,(k_1 + 1)}{f(t,d) + k_1 \left(1 - b + b\, \frac{|d|}{\mathrm{avgdl}}\right)}
```

with the standard defaults `k_1 = 1.5`$ and `b = 0.75`$.

## The Code

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
         (q-terms (remove-duplicates (tokenize query) :test #'string=)))
    (labels ((idf (term)
               (let ((df (count-if (lambda (d)
                                     (member term d :test #'string=))
                                   docs)))
                 (log (+ 1.0 (/ (+ (- n df) 0.5) (+ df 0.5)))))))
      (sort (loop for doc in docs
                  for raw in corpus
                  for len in lens
                  for score =
                  (loop for term in q-terms
                        for tf = (count term doc :test #'string=)
                        when (> tf 0)
                        sum (* (idf term)
                               (/ (* tf (+ k1 1.0))
                                  (+ tf (* k1
                                           (+ (- 1.0 b)
                                              (* b (/ len avgdl))))))))
                  when (> score 0.0)
                  collect (list score raw))
            #'> :key #'car))))

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

## How It Works

- `tokenize` is a hand-rolled scanner written with `loop`: accumulate alphanumeric characters (downcased), and emit a word whenever a non-alphanumeric character ends the run.
- `idf` is defined locally with `labels` since it closes over the document set; it counts how many documents contain the term with `count-if`.
- The scoring `loop` iterates documents, raw strings, and lengths in parallel (`for ... for ... for ...`), computing each document's score as a sum over unique query terms. `remove-duplicates` on the query terms prevents a repeated word from double-counting.
- The `k_1`$ parameter controls term-frequency saturation and `b`$ controls how much long documents are penalized relative to the average length `\mathrm{avgdl}`$.

## Running It

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

Note how "search ranking" ranks the BM25 document first even though the query words appear in other documents too — `idf` rewards discriminative terms.

## Using It

BM25 is a strong baseline for any local keyword-search task: your notes, a documentation set, log files. It also complements the vector-store chapter nicely — hybrid search systems routinely merge BM25 (exact keyword match) with embedding similarity (semantic match). The `(score document)` pairs come back sorted, ready to truncate to a top-`k`$ list.

# Associative Memory with Hopfield Networks

File: `hopfield.lisp`

A Hopfield network stores patterns as attractors of a dynamical system: train it with Hebbian learning, then present a corrupted pattern and let the network settle back into the nearest stored memory.

Training on bipolar patterns `x^{(p)} \in \{-1, +1\}^N`$ sets the weights to the outer-product sum:

```$
w_{ij} = \sum_{p} x_i^{(p)} x_j^{(p)} \quad (i \neq j), \qquad w_{ii} = 0
```

Recalling iterates the sign rule `s_i \leftarrow \mathrm{sgn}\!\left(\sum_j w_{ij} s_j\right)`$, which monotonically decreases the energy:

```$
E(s) = -\frac{1}{2} \sum_{i=1}^{N} \sum_{j=1}^{N} w_{ij}\, s_i\, s_j
```

so the state slides downhill into a stored pattern.

## The Code

```lisp
;; sbcl --script hopfield.lisp (Hopfield associative neural network)

(defun hopfield-train (patterns size)
  (let ((w (make-array (list size size) :initial-element 0)))
    (dolist (p patterns w)
      (dotimes (i size)
        (dotimes (j size)
          (unless (= i j)
            (incf (aref w i j) (* (nth i p) (nth j p)))))))))

(defun hopfield-recall (w input &optional (steps 5))
  (let ((state (copy-seq input))
        (n (length input)))
    (dotimes (_ steps state)
      (dotimes (i n)
        (let ((sum (loop for j below n
                         sum (* (aref w i j) (nth j state)))))
          (setf (nth i state) (if (>= sum 0) 1 -1)))))))

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
                  (setf (nth idx cp) (- (nth idx cp))))))
       (recalled (hopfield-recall w noisy)))
  (format t "Original Pattern 'X' (Energy: ~,1f):~%"
          (hopfield-energy w pattern-x))
  (show-pattern pattern-x)
  (format t "~%Noisy Pattern with 3 bit-flips (Energy: ~,1f):~%"
          (hopfield-energy w noisy))
  (show-pattern noisy)
  (format t "~%Recalled Associative Memory (Energy: ~,1f):~%"
          (hopfield-energy w recalled))
  (show-pattern recalled)
  (format t "~%Recovered perfectly? ~a~%" (equal recalled pattern-x)))
```

## How It Works

- `hopfield-train` accumulates the outer product of each pattern into an `N \times N`$ weight matrix, skipping the diagonal — the entire learning rule is one `incf`.
- `hopfield-recall` copies the input (so the caller's list is not mutated) and runs `steps` sweeps of synchronous updates; `(if (>= sum 0) 1 -1)` is the sign activation.
- `hopfield-energy` computes the Lyapunov function above — useful for watching recall make progress, as the demo shows.
- `show-pattern` renders a bipolar list as a `#`/`.` grid.

## Running It

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

Recovered perfectly? T
```

The corrupted pattern starts at energy `-52.0`; five update sweeps pull it back to the stored `X` at energy `-144.0`, recovering the original exactly.

## Using It

Hopfield networks are a lovely teaching tool — attractor dynamics, Hebbian learning, and energy minimization in sixty lines. Practically, their capacity is limited (roughly `0.15N`$ random patterns before interference sets in), but the same outer-product idea reappears in modern associative-memory and attention literature. Try training on the `O` pattern, corrupting *it*, and confirming recall lands in the right attractor; then push past capacity and watch it create spurious mixtures.

# A Tiny Triple Store

File: `triple-store.lisp`

An RDF-style triple store with a pattern-matching query engine in under thirty lines: variables, unification against the store, and relational joins across multiple patterns.

## The Code

```lisp
;; sbcl --script triple-store.lisp (in-memory RDF triple store)

(defvar *store* nil)

(defun add-triple (s p o &optional (store-var '*store*))
  (push (list s p o) (symbol-value store-var)))

(defun var-p (x)
  (and (symbolp x) (char= (char (symbol-name x) 0) #\?)))

(defun match-triple (pat triple env)
  (loop for p in pat for x in triple
        do (cond ((eq env :fail) (return :fail))
                 ((var-p p)
                  (let ((b (assoc p env)))
                    (if b (unless (equal (cdr b) x) (return :fail))
                        (push (cons p x) env))))
                 ((not (equal p x)) (return :fail)))
        finally (return env)))

(defun query-triples (patterns &optional (store *store*) (envs '(())))
  (if (null patterns) envs
      (query-triples
       (cdr patterns) store
       (loop for env in envs
             append
             (loop for tr in store
                   for next-env = (match-triple (car patterns)
                                                tr
                                                (copy-alist env))
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

## How It Works

- The store `*store*` is just a list of `(subject predicate object)` triples; `add-triple` pushes onto it. The `store-var` parameter defaults to the special variable but lets you keep several stores.
- A "variable" is any symbol whose name starts with `?` (`var-p`) — a lightweight convention borrowed from SPARQL.
- `match-triple` unifies one pattern against one triple given a binding environment (an alist): a variable already bound must match its binding, an unbound variable gets bound, a literal must be `equal`. It returns the extended environment or the keyword `:fail`.
- `query-triples` is where the join happens: it threads a *list* of environments through the pattern list. For each pattern it tries every triple against every live environment (on a `copy-alist`, so failed branches never pollute sibling bindings) and keeps the successes. Two patterns mentioning the same variable therefore act as a relational join.

## Running It

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

Query 2 is the one to study: `?who` gets bound by the first pattern, and the second pattern only succeeds where that same binding is a philosopher — Descartes alone survives.

## Using It

This is the core of a miniature Datalog. Extend it with recursive rules or negation-as-failure and you have a little logic language; point it at the output of the SPARQL chapter and you can cache and join remote knowledge-graph results locally. For a handful of triples in a script, it is often all the "database" you need.

# A Tiny Vector Store

File: `vector-store.lisp`

Embedding-based semantic search, reduced to its essence: a hash table of labeled vectors and cosine-similarity ranking.

Cosine similarity measures the angle between two vectors, ignoring their magnitudes:

```$
\mathrm{cosine}(a, b) = \frac{a \cdot b}{\lVert a \rVert \, \lVert b \rVert}
```

## The Code

```lisp
;; sbcl --script vector-store.lisp (in-memory dense vector store)

(defun v-dot (a b)
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

## How It Works

- `v-dot` iterates two vectors in lockstep with `loop ... across`, and `v-norm` reuses it for the Euclidean norm `\lVert a \rVert = \sqrt{a \cdot a}`$.
- `v-cosine` guards against division by zero — a zero vector is defined to have similarity `0.0`$ with everything.
- The store maps `id` to `(text vector)` in an `equal` hash table, so string IDs work. `store-add` coerces lists to vectors so callers can pass either.
- `store-search` scores every entry, sorts descending, and returns the top `k`$ as `(score id text)` triples. `min` keeps `subseq` in bounds when the store holds fewer than `k`$ items.

## Running It

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

The demo uses hand-made 4D vectors whose axes loosely encode royalty, gender, and fruitness. Query 1 (high royalty, female) ranks "queen" and "princess" above "king"; query 2 ranks the fruits above everything.

## Using It

Replace the toy vectors with real embeddings from an API (Gemini and Ollama both offer embedding endpoints) and this exact code becomes a semantic search engine over your documents: chunk text, embed each chunk, `store-add`, then `store-search` with the embedded question. Brute-force scoring is fine for thousands of vectors; beyond that, look at approximate-nearest-neighbor indexes — the interface here (add, search top-`k`$) is designed to look like one.

# Extractive Text Summarization

File: `summarizer.lisp`

A classic pre-neural trick: score each sentence by the average frequency of its significant words, keep the top few, and present them in their original order.

```$
\mathrm{score}(s) = \frac{1}{|s|} \sum_{w \in s} \mathrm{freq}(w)
```

where `\mathrm{freq}(w)`$ counts occurrences of word `w`$ across the whole document, ignoring a small stop-word list.

## The Code

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
              (sort (subseq (sort scored #'> :key #'first)
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

## How It Works

- `words` and `split-sentences` are the same hand-rolled scanner pattern as the BM25 chapter: `loop` over characters, accumulate, emit on boundaries. Sentences break on `.`, `!`, or `?`.
- Frequencies accumulate in an `equal` hash table, skipping `*stop-words*` so common function words do not dominate the scores.
- Each sentence's score is the *average* of its word frequencies — dividing by sentence length prevents long sentences from winning merely by containing more words.
- The last expression is the subtle part: `sort` by score descending, take the top `n` with `subseq`, then `sort` *again* by the original sentence index ascending. That second sort restores document order so the summary reads naturally.
- `summarize` never mutates its input; the scoring triples `(score idx s)` carry the index through both sorts.

## Running It

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

## Using It

Feed it the output of the web-scraping chapter — `(summarize (page-text url) 3)` summarizes a web page without any AI service. It also works as a compression stage in front of an LLM: extract the top sentences locally, then ask Gemini or Ollama for an abstractive rewrite of just those. Adjust `*stop-words*` for your domain, and treat the sentence splitter as a heuristic (abbreviations like "Dr." will fool it).

# Symbolic Polynomial Math

File: `symbolic-math.lisp`

A tiny computer-algebra kernel: polynomials as association lists, exact rational arithmetic, derivatives, integrals, and definite integrals by the fundamental theorem of calculus.

A polynomial is stored as a sorted alist of `(exponent . coefficient)` pairs with like terms combined and zeros dropped — so `3x^2 - x + 5`$ is `((2 . 3) (1 . -1) (0 . 5))`. The calculus is the power rule in both directions:

```$
\frac{d}{dx} x^n = n\, x^{n-1}, \qquad \int x^n\, dx = \frac{x^{n+1}}{n+1}
```

and definite integrals evaluate the antiderivative at the endpoints:

```$
\int_a^b p(x)\, dx = F(b) - F(a)
```

## The Code

```lisp
;;;; symbolic-math.lisp: symbolic polynomial calculus.
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

(defun bound (b)
  (case b (:pi pi) (:e (exp 1d0)) (t (float b 1d0))))

(defun definite (p a b)
  (let ((f (integ p)))
    (- (evaluate f (bound b)) (evaluate f (bound a)))))

(defun critical-point-p (p x &optional (tol 1d-9))
  (< (abs (evaluate (deriv p) x)) tol))

;;; Display
(defun ->string (p &optional (v 'x))
  (if (null p) "0"
      (format nil "~{~a~^ + ~}"
              (loop for (e . c) in p
                    collect (format nil "~a~@[~(~a~)~]~@[^~a~]"
                                    c (and (> e 0) v)
                                    (and (> e 1) e))))))

(defun integral->string (p &optional a b (v 'x))
  (flet ((show (b) (case b (:pi "π") (:e "e") (t b))))
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

## How It Works

- `normalize` is the invariant-keeper: it sums coefficients per exponent in a hash table, drops zero coefficients, and sorts by descending exponent. Every constructor and arithmetic function funnels through it, so polynomials are always in canonical form.
- `poly` builds a polynomial from coefficients highest-degree first: `(poly 3 -1 5)` means `3x^2 - x + 5`$.
- Because coefficients are ordinary Lisp numbers, ratios stay exact — the antiderivative of `3x^2`$ has coefficient `3/3 = 1`$, but the antiderivative of `-x`$ genuinely carries the rational `-\frac{1}{2}`$.
- `deriv` and `integ` take an optional repetition count: `(deriv p 3)` is the third derivative, computed by recursing on the single-step rule. The constant term vanishes under `deriv` via the `unless (zerop e)` clause.
- `bound` lets integration bounds be numbers or the keywords `:pi` and `:e`, converting everything to a double float — which is why `definite` results print with the `d0` double-float marker.
- `critical-point-p` checks whether `p'(x) = 0`$ within a tolerance — for a quadratic, the exact answer: `p'(x) = 6x - 1 = 0`$ at `x = 1/6`$.
- `->string` and `integral->string` are pure `format` exercises: `~@[...~]` prints a group only when its argument is non-nil, which is how the variable and exponent appear conditionally. Note the literal-minded `3x^2 + -1x + 5` in the output below: `->string` never special-cases negative coefficients — teaching it to print `- x` instead of `+ -1x` is a good first exercise.

## Running It

```bash
$ sbcl --script symbolic-math.lisp
```

Actual output:

```text
p          : 3x^2 + -1x + 5
p + q      : 3x^2 + 7
p - q      : 3x^2 + -2x + 3
2p         : 6x^2 + -2x + 10
degree, p(2): 2, 15
p', p'', p''': 6x + -1 | 6 | 0
∫p, ∫∫p    : 1x^3 + -1/2x^2 + 5x | 1/4x^4 + -1/6x^3 + 5/2x^2
∫[0,1](3x^2 + -1x + 5) dx = 5.5d0
∫[0,π](3x^2 + -1x + 5) dx = 41.7794
x=1/6 critical? T  x=0? NIL
```

Check the seventh line against the symbolic answer:

```$
\int_0^1 (3x^2 - x + 5)\, dx = \left[ x^3 - \frac{1}{2} x^2 + 5x \right]_0^1 = 1 - \frac{1}{2} + 5 = 5.5
```

The exact rational antiderivative (`-1/2x^2`, `5/2x^2` in the output) is visible before evaluation converts anything to floats.

## Using It

Handy for checking calculus homework, generating exact examples for teaching material, or serving as the symbolic core of a bigger system. Natural extensions: polynomial multiplication (convolve the alists), rational functions as pairs of polynomials, or a `solve` for quadratic roots. The representation decision — canonical alists — is what keeps every operation a one-liner; it is worth studying as much as the calculus.

# Scalar Automatic Differentiation

File: `autograd.lisp`

The engine inside every neural-network library, in sixty lines: build a computation graph of scalar operations, then walk it in reverse accumulating gradients via the chain rule.

Each node records its value, its parents, and a closure implementing the *local* gradient of its operation. Reverse-mode differentiation seeds the output's gradient at `1`$ and propagates backward: for `c = a \cdot b`$ the local rules are `\partial c / \partial a = b`$ and `\partial c / \partial b = a`$; for addition both partials are `1`$; for `\mathrm{relu}`$ the gradient flows only where the output is positive.

## The Code

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
  (format t "Gradients after e.backward():~%")
  (format t "  de/de = ~4,2f~%" (val-grad e))
  (format t "  de/dd = ~4,2f~%" (val-grad d))
  (format t "  de/dc = ~4,2f  (expected 1.0)~%" (val-grad c))
  (format t "  de/da = ~4,2f  (expected b = -3.0)~%" (val-grad a))
  (format t "  de/db = ~4,2f  (expected a = 2.0)~%" (val-grad b)))
```

## How It Works

- `defstruct` with a renamed internal constructor `%val` is a common Lisp pattern: the public function `val` then acts as a smart constructor that coerces numbers to floats and passes existing nodes through untouched. That is what lets `v+` accept `(v+ 2 x)` as easily as `(v+ x y)`.
- Each operation builds its output node, then installs a `backward` closure capturing the inputs. The closure *accumulates* (`incf`) into parent gradients rather than assigning — required for correctness when a value feeds into the graph more than once.
- `backward` does a depth-first topological sort of the graph (`labels` defines the local recursive `build`; an `eq` hash table tracks visited nodes), seeds the root's gradient at `1.0`$, and fires the closures in reverse-topological order — root first — so every node's gradient is final before its own closure runs.
- `op` is stored purely for inspection/debugging; the computation lives entirely in the closures.

## Running It

```bash
$ sbcl --script autograd.lisp
```

Actual output:

```text
Forward:  d = (a * b) + c = (2.0 * -3.0) + 10.0 = 4.0
          e = relu(d) = 4.0
Gradients after e.backward():
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

— matching the program exactly.

## Using It

This is Andrej Karpathy's *micrograd* idea, ported to Lisp. To grow it into a trainable neuron: add `v-tanh` or `v-exp` (each needs only its local gradient), build a dot product out of `v*` and `v+`, and write a training loop that calls `backward` on a loss node and nudges the leaf values by `-lr * grad`. One caveat: gradients accumulate into `val-grad`, so zero them between training steps — a one-line `zero-grad` walk over the topo list.

{appendix}

# Loading Everything Interactively

File: `load.lisp`

All sixteen example programs in this book (every file except `load.lisp` itself — the seventeenth file) end with demo calls, which is convenient for scripts but annoying when you want every definition in one REPL without the demos firing. `load.lisp` solves that with a simple trick: read each file form by form, and `eval` only the definition forms.

## The Code

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
```

## How It Works

- The loader finds its own directory with `*load-truename*`, iterates every `.lisp` file except itself, and reads forms with `(read s nil s)` — using the stream itself as the eof marker, a classic idiom.
- Only forms whose `car` is in the whitelist (`defun`, `defstruct`, `defvar`, `defparameter`, ...) get evaluated. Top-level demo calls are simply skipped, which is exactly why the book's files can each end in executable demos yet still be loaded en masse.
- `*package*` is bound to `cl-user` while reading, so symbols read consistently no matter what package the REPL is in.
- `*help*` is a data-driven catalog: one-entry sublists are section headers (file names), two-entry sublists are `(signature . description)` pairs.
- `help` prints everything, or only rows matching a filter string (matched case-insensitively against both signature and description), and returns `(values)` — no return value — to keep the REPL tidy.

## Running It

```lisp
* (load "load.lisp")
* (help "search")
  (esearch "query" [n])              ; Exa search -> (title url text)
  (bsearch "query" [n])              ; Brave search -> (title url text)
  (bm25-search corpus query)         ; Okapi BM25 ranked document retrieval
  (store-search store qvec [k])      ; top-K nearest neighbors by cosine similarity
```

The filter is an ordinary substring match, so `(help "search")` conveniently surfaces both the web-search APIs and the two local retrieval engines. Calling `(help)` with no argument prints the whole catalog grouped by file.

## Using It

Treat `load.lisp` as a workbench: load everything once, then mix the chapters in a single session. For example, rank documents with BM25 and summarize the hits — two chapters composed with no glue code (real transcript):

```lisp
* (defparameter *corpus*
    '("Common Lisp is a general-purpose programming language with powerful macros."
      "Python is an interpreted language known for data science and machine learning."
      "Deep learning models require automatic differentiation and gradient optimization."))
*CORPUS*
* (summarize (format nil "~{~a ~}" (mapcar #'second (bm25-search *corpus* "learning"))) 1)
("Deep learning models require automatic differentiation and gradient optimization.")
```

Other one-liners to try: `(summarize (page-text url) 3)`, `(backward e)` after building a graph with `v+` and `v*`. The selective-`eval` trick itself is worth stealing for your own script collections: it turns a directory of runnable programs into an importable library without touching the files.
