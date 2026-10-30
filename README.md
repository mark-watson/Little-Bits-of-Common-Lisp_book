# Little Bits of Common Lisp

By **Mark Watson**

- Author Website: <https://markwatson.com>
- Leanpub Book Page: <https://leanpub.com/little-bits-of-common-lisp>

This repository contains the complete source code for the book *Little Bits of Common Lisp* by Mark Watson.

---

## About the Book

*Little Bits of Common Lisp* presents seventeen self-contained Common Lisp programs. Each chapter in the book focuses on one single `.lisp` file. Most files contain fewer than one hundred lines of code. You can read each program in a few minutes and execute it directly from your terminal using Steel Bank Common Lisp (SBCL).

The book avoids partial snippets. Every chapter prints the full code, describes how the code functions, displays sample output, and explains how you can adapt the code for your own work.

The examples cover modern engineering needs as well as classic artificial intelligence algorithms:

- Calling large language models: Apple on-device models, Google Gemini, and local Ollama instances.
- Interacting with the web: querying search engines (Exa and Brave), querying SPARQL knowledge graphs (DBpedia and Wikidata), scraping HTML pages, and rendering client-side JavaScript with a headless browser.
- Automating desktop tasks: controlling macOS applications with AppleScript.
- Implementing algorithms from scratch: Bayesian probability updates, BM25 document ranking, Hopfield neural networks, an RDF-style triple store, a dense vector store, an extractive text summarizer, symbolic polynomial calculus, and reverse-mode automatic differentiation.

### Design Principles

1. **One file per task**: Each file contains everything it needs to run. You do not need to install complex multi-file project frameworks.
2. **Minimal external libraries**: The algorithm chapters use standard Common Lisp with zero third-party dependencies.
3. **External tools for networking**: Network programs call the system `curl` command through `uiop:run-program` instead of importing large HTTP client libraries. This design removes compilation issues, drops foreign library bindings, and keeps code short.
4. **JSON with Jzon**: When programs must parse structured API output, they load `com.inuoe.jzon` via Quicklisp.
5. **Immediate execution**: Every script runs directly with `sbcl --script filename.lisp`.

---

## Requirements and Dependencies

All programs run on SBCL. Several programs need Quicklisp to fetch light utility libraries. Network examples require `curl`.

| Program | External Tools | Quicklisp Systems | Environment Variables |
|---|---|---|---|
| `apple-system-model.lisp` | macOS, `fm` CLI | None | None |
| `gemini.lisp` | `curl` | `com.inuoe.jzon` | `GOOGLE_API_KEY` |
| `ollama.lisp` | `curl`, local `ollama` daemon | `com.inuoe.jzon` | None |
| `search.lisp` | `curl` | `com.inuoe.jzon` | `EXA_SEARCH_API_KEY`, `BRAVE_SEARCH_API_KEY` |
| `sparql.lisp` | `curl` | `com.inuoe.jzon` | None |
| `lightpanda.lisp` | `lightpanda` binary | None | None |
| `webscraping.lisp` | `curl` | `plump` | None |
| `osascript.lisp` | macOS, `osascript` | None | None |
| `bayes.lisp` | None | None | None |
| `bm25.lisp` | None | None | None |
| `hopfield.lisp` | None | None | None |
| `triple-store.lisp` | None | None | None |
| `vector-store.lisp` | None | None | None |
| `summarizer.lisp` | None | None | None |
| `symbolic-math.lisp` | None | None | None |
| `autograd.lisp` | None | None | None |
| `load.lisp` | None | Loaded as needed | Inherits script settings |

---

## How to Run the Programs

### Run Individual Scripts

Run any program from your shell with `sbcl --script`:

```bash
# Run the Bayesian inference example
sbcl --script bayes.lisp

# Run the BM25 document ranking example
sbcl --script bm25.lisp

# Run the symbolic math calculus example
sbcl --script symbolic-math.lisp

# Run the reverse-mode autograd example
sbcl --script autograd.lisp
```

For scripts that access network APIs, export the appropriate API keys first:

```bash
export GOOGLE_API_KEY="your-gemini-key"
sbcl --script gemini.lisp

export EXA_SEARCH_API_KEY="your-exa-key"
export BRAVE_SEARCH_API_KEY="your-brave-key"
sbcl --script search.lisp
```

### Load All Programs Interactively

The file `load.lisp` allows you to load every function and structure definition into an interactive REPL session. It reads each `.lisp` file, evaluates definitions (`defun`, `defstruct`, `defparameter`, `defvar`), and skips the demo test runs at the bottom of the files.

Start SBCL and load `load.lisp`:

```lisp
$ sbcl
* (load "load.lisp")
```

After loading, call the `help` function to inspect available functions:

```lisp
* (help)
```

You can also filter the command list by keyword:

```lisp
* (help "store")
* (help "poly")
```

---

## Detailed Overview of the Programs

### 1. Large Language Models and Modern AI

#### On-Device AI with Apple Foundation Models (`apple-system-model.lisp`)
Modern versions of macOS include Apple on-device foundation models. The system exposes these models through the `fm` command-line utility. In nine lines of code, `apple-system-model.lisp` invokes `fm respond --no-stream` using `uiop:run-program`. The function `apple-fm` takes a prompt string, runs the model locally, and returns the trimmed text answer. It requires no network access, no account credentials, and no billing setup.

#### Google Gemini API (`gemini.lisp`)
This eighteen-line program queries Google's Gemini models via their REST endpoints. It reads `GOOGLE_API_KEY` from the environment, packs your prompt into a JSON payload with `com.inuoe.jzon`, and pipes the request to `curl`. It extracts the generated text from the JSON candidate list and returns a clean string. The default model is `gemini-3.5-flash-lite`.

#### Local LLMs with Ollama (`ollama.lisp`)
Developers who want private local inference on Linux, Windows, or macOS can run Ollama. The script `ollama.lisp` posts JSON payloads to `http://localhost:11434/api/generate`. It disables streaming so Ollama returns the full completion in a single JSON document. The function `ollama` defaults to the `mistral` model, but you can pass any model tag that you have pulled into your local Ollama instance.

---

### 2. Web Data, Search Engines, and Semantic Web

#### Web Search with Exa and Brave Search (`search.lisp`)
Language model agents and data pipelines frequently need fresh web data. `search.lisp` demonstrates two search APIs:
- `esearch`: Queries the Exa neural search API (`https://api.exa.ai/search`), requesting highlights and summaries.
- `bsearch`: Queries the Brave Search keyword API (`https://api.search.brave.com/res/v1/web/search`).

The helper `curl-json` handles headers and authorization. Both search functions return uniform lists containing `(title url text)` tuples, so you can swap search providers without changing downstream processing code.

#### Knowledge Graphs with SPARQL (`sparql.lisp`)
The Semantic Web stores vast webs of linked facts in RDF format. `sparql.lisp` queries public SPARQL endpoints using standard HTTP GET requests. The function `sparql` issues queries with an `Accept: application/sparql-results+json` header, parses the variable bindings, and converts each result row into an association list of `(variable-name . string-value)`. The file provides convenient helper wrappers `dbpedia` and `wikidata` to query DBpedia and Wikidata directly.

#### Headless Browser Rendering with Lightpanda (`lightpanda.lisp`)
Modern web pages rely heavily on client-side JavaScript execution. Static HTTP requests fail to capture content generated by browser scripts. `lightpanda.lisp` controls Lightpanda, a fast headless browser binary designed for AI scrapers. The script runs `lightpanda dump <url>` to obtain fully rendered DOM output, or `lightpanda dump --format markdown <url>` to obtain clean Markdown. A companion function, `links`, extracts all hyperlink targets from the rendered HTML.

#### Web Scraping with Plump (`webscraping.lisp`)
When pages provide static HTML, `webscraping.lisp` downloads the markup with `curl` and parses it into an in-memory document tree using the `plump` library. The script defines:
- `fetch`: Downloads and parses an HTML document into a DOM node.
- `text`: Recursively collects all text from child nodes.
- `clean`: Removes excess spaces and compresses multiple blank lines.
- `headers`: Gathers text from all heading tags (`h1` through `h6`).
- `page-text`: Strips out `<script>` and `<style>` blocks and returns readable plain text.

---

### 3. Operating System Automation

#### Automating macOS Applications (`osascript.lisp`)
On macOS, Common Lisp can control desktop software through AppleScript and the system `osascript` command. The function `osascript` takes an AppleScript string, executes it via `uiop:run-program`, and returns standard output. Using this mechanism, `osascript.lisp` implements:
- `mail-unread-count`: Queries Apple Mail for the count of unread messages in the inbox.
- `get-todays-events`: Inspects Apple Calendar and lists the titles of all events scheduled for today.
- `add-reminder`: Creates a new entry in Apple Reminders with a title and an optional due date.
- `send-imessage`: Sends an SMS or iMessage to a phone number or contact via the Messages application.
- `read-recent-imessages`: Queries the local Messages SQLite database (`~/Library/Messages/chat.db`) to return recent message text and sender information.
- `safari-login`: Automates Safari by loading a target web page, filling in username and password input fields through JavaScript execution, and clicking the submit button.

---

### 4. Classic AI, Information Retrieval, and Knowledge Representation

#### Bayesian Inference (`bayes.lisp`)
Bayes' Theorem provides the mathematical foundation for updating beliefs when you observe new evidence. In under thirty lines, `bayes.lisp` implements:
- `bayes-normalize`: Scales probabilities across a discrete distribution so they sum to 1.0.
- `bayes-update`: Multiplies prior probabilities by the likelihood of observed evidence and normalizes the posterior distribution.
- `map-hypothesis`: Identifies the Maximum A Posteriori (MAP) hypothesis from a probability distribution.

The demo simulates the classic medical screening base-rate fallacy: a disease has 1% prevalence, and a screening test has 95% sensitivity with a 5% false positive rate. The code shows why a patient who tests positive once has only a 16.1% probability of having the disease, while a second consecutive positive test raises that probability to 78.5%.

#### Okapi BM25 Document Ranking (`bm25.lisp`)
Okapi BM25 remains one of the most effective algorithms for information retrieval and search ranking. `bm25.lisp` builds BM25 scoring from fundamental mathematics:
- `tokenize`: Splits text into lowercase alphanumeric words.
- `doc-frequencies`: Counts the number of documents in a collection that contain each term.
- `idf`: Computes the Robertson-Spärck Jones inverse document frequency with smoothing.
- `bm25-score`: Scores a document against a query using term frequencies, inverse document frequency, document length, and average collection length (with parameters `k1 = 1.5` and `b = 0.75`).
- `bm25-search`: Ranks an entire corpus of documents against a user query and returns matching documents sorted by score.

#### Hopfield Associative Memory Networks (`hopfield.lisp`)
Hopfield networks model associative memory. Unlike address-based memory in digital computers, associative memory retrieves complete patterns when presented with partial or corrupted inputs. `hopfield.lisp` creates an auto-associative network with bipolar states (`+1` and `-1`):
- `hopfield-train`: Computes a symmetric weight matrix from training patterns using outer products (Hebbian learning) while setting self-connections to zero.
- `hopfield-energy`: Evaluates the scalar Lyapunov energy of the network state. The energy decreases or stays constant with each update step.
- `hopfield-recall`: Updates neurons asynchronously until the state converges to a stable energy minimum.
- `show-pattern`: Formats bipolar arrays into readable two-dimensional ASCII grids.

The demo trains a 25-neuron network on 5x5 pixel patterns of the letters 'O' and 'X', corrupts the patterns with noise, and watches the network restore the original patterns within two update cycles.

#### In-Memory RDF Triple Store (`triple-store.lisp`)
Knowledge representation systems often store facts as subject-predicate-object triples. `triple-store.lisp` builds an in-memory graph database:
- `add-triple`: Inserts `(subject predicate object)` records into a list store.
- `match-pattern`: Compares a triple pattern against a stored triple. Symbols beginning with a question mark (such as `?x` or `?name`) act as variables that bind to matched values.
- `query-triples`: Evaluates conjunctions of triple patterns. It matches patterns sequentially, carries variable bindings forward, and joins results across relations.

The demo populates a family tree and academic department graph, then runs multi-clause queries to find siblings, advisor-student links, and department colleagues.

#### Dense Vector Store (`vector-store.lisp`)
Vector databases support modern retrieval-augmented generation (RAG) by finding documents with semantic similarity to a prompt. `vector-store.lisp` builds an in-memory vector store from scratch:
- `v-dot`: Calculates the dot product of two numerical lists.
- `v-norm`: Computes the Euclidean length (L2 norm) of a vector.
- `v-cosine`: Calculates the cosine of the angle between two vectors.
- `store-add`: Inserts an item consisting of an identifier, text string, and dense numerical embedding vector.
- `store-search`: Measures cosine similarity between a query vector and every stored entry, sorting and returning the top `k` closest matches.

#### Extractive Text Summarizer (`summarizer.lisp`)
Before large language models existed, natural language processing relied on statistical frequency methods to summarize articles. `summarizer.lisp` implements an extractive summarizer:
- `words`: Extracts normalized lowercase words from text.
- `split-sentences`: Divides an article into individual sentences based on terminal punctuation.
- `term-frequencies`: Calculates the frequency of each non-stopword word across the text.
- `sentence-score`: Scores each sentence by summing the frequencies of its constituent words, normalized by sentence length.
- `summarize`: Selects the top `n` highest-scoring sentences and outputs them in their original document order to preserve narrative structure.

---

### 5. Mathematics and Deep Learning Foundations

#### Symbolic Polynomial Calculus (`symbolic-math.lisp`)
Common Lisp excels at symbolic processing because code and data share the same list representations. `symbolic-math.lisp` implements an algebra engine for single-variable polynomials:
- Representation: A polynomial $a_n x^n + \dots + a_1 x + a_0$ is represented as a list of term structures, each storing a coefficient and an exponent.
- `poly`: Constructs a polynomial from a list of coefficients.
- `p+` and `p-`: Adds and subtracts polynomials, combining like terms.
- `scale`: Multiplies a polynomial by a scalar factor.
- `evaluate`: Calculates the numeric value of $p(x)$ for a given scalar $x$.
- `deriv`: Computes the formal symbolic derivative: $\frac{d}{dx} a x^n = a n x^{n-1}$.
- `integ`: Computes the formal indefinite integral: $\int a x^n dx = \frac{a}{n+1} x^{n+1}$.
- `definite`: Evaluates the definite integral $\int_{a}^{b} p(x) dx$ using the Fundamental Theorem of Calculus.
- `critical-point-p`: Tests whether $p'(x) = 0$ at a candidate point.
- `->string` and `integral->string`: Formats polynomials and definite integrals into readable mathematical strings.

#### Scalar Automatic Differentiation (`autograd.lisp`)
Modern deep learning frameworks compute parameter gradients using automatic differentiation. `autograd.lisp` implements reverse-mode automatic differentiation over a directed acyclic graph (DAG) of scalar values, inspired by Andrej Karpathy's `micrograd`:
- `val`: Constructs a computation node storing scalar data, accumulated gradient, parent pointers, and an operation tag.
- `v+`: Performs addition on two nodes and registers a backward closure that passes downstream gradients to both parents.
- `v*`: Performs multiplication on two nodes and registers a backward closure that applies the product rule: $\frac{\partial (ab)}{\partial a} = b$, $\frac{\partial (ab)}{\partial b} = a$.
- `v-relu`: Computes the Rectified Linear Unit activation function ($\max(0, x)$) and passes gradients only when the input is positive.
- `backward`: Performs a topological sort on the computation graph starting from the loss node, sets the output gradient to `1.0`, and walks backward through the nodes to propagate gradients to all leaves via the chain rule.

The demo evaluates a small expression graph, runs backpropagation, and prints exact analytical derivatives matching manual calculus calculations.

---

## Architectural Lessons and Highlights

### Why Shell Out to `curl`?

Several chapters make HTTP requests to web servers and REST APIs. Instead of importing heavy Common Lisp HTTP clients (such as Drakma or Dexador), these programs invoke `curl` via `uiop:run-program`:

```lisp
(uiop:run-program (list "curl" "-s" "-X" "POST" url ...) :output :string)
```

This choice offers several practical benefits:
- **Zero foreign dependency compilation**: Heavy HTTP libraries often depend on foreign OpenSSL C libraries, socket backends, or complex stream abstractions. `curl` comes pre-installed on macOS and Linux systems.
- **Robust protocol handling**: `curl` reliably handles TLS certificates, HTTP/2, redirection, and proxy settings without additional Lisp code.
- **Portability**: The resulting Common Lisp files remain tiny, predictable, and simple to understand.

### Pure Common Lisp for Algorithmic Clarity

The chapters covering Bayesian inference, BM25 ranking, Hopfield networks, the triple store, the vector store, the summarizer, symbolic calculus, and automatic differentiation require no libraries beyond standard Common Lisp.

These implementations demonstrate the strengths of Common Lisp:
- First-class functions and closures allow concise mathematical expressions.
- Built-in data structures (association lists, hash tables, vectors, structures) provide efficient performance with minimal syntax.
- Exact rational arithmetic prevents rounding errors in polynomial integration and calculus.

---

## About the Author

**Mark Watson** is an engineer, author, and researcher in artificial intelligence, Common Lisp, semantic web technologies, and natural language processing. He has written over twenty books on artificial intelligence and software engineering, including *Common Lisp Recipes*, *Practical Semantic Web and Linked Data Technologies*, and *Loving Common Lisp*.

Visit his website for articles, books, and software repositories:
- <https://markwatson.com>

Get the book on Leanpub:
- <https://leanpub.com/little-bits-of-common-lisp>

---

## License

This software and text are released under the GNU Affero General Public License v3 (AGPL-3.0). See the `AGPL-v3.txt` file in this repository for full license terms.
