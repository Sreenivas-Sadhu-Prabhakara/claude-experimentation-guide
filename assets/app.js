/* ════════════════════════════════════════════════════════════════
   The Fable Field Guide — interactivity
   Vanilla JS, no dependencies. Everything degrades gracefully:
   if this file never loads, the page is still a complete guide.
   ════════════════════════════════════════════════════════════════ */
(function () {
  "use strict";

  /* ── 1. ELI5 ↔ technical mode toggle ──────────────────────── */
  const modeBtns = document.querySelectorAll(".mode-btn");
  const blocks = document.querySelectorAll("[data-mode-block]");

  function setMode(mode) {
    modeBtns.forEach((b) => {
      const on = b.dataset.mode === mode;
      b.classList.toggle("is-active", on);
      b.setAttribute("aria-pressed", String(on));
    });
    blocks.forEach((el) => {
      const isEli5 = el.classList.contains("mode-eli5");
      const show = (mode === "eli5" && isEli5) || (mode === "tech" && !isEli5);
      el.hidden = !show;
    });
    try { localStorage.setItem("fable-mode", mode); } catch (e) {}
  }
  modeBtns.forEach((b) => b.addEventListener("click", () => setMode(b.dataset.mode)));
  let savedMode = "eli5";
  try { savedMode = localStorage.getItem("fable-mode") || "eli5"; } catch (e) {}
  setMode(savedMode);

  /* ── 2. expandable difference cards ───────────────────────── */
  document.querySelectorAll(".dcard").forEach((card) => {
    card.setAttribute("role", "button");
    card.setAttribute("tabindex", "0");
    const toggle = () => card.classList.toggle("open");
    card.addEventListener("click", toggle);
    card.addEventListener("keydown", (e) => {
      if (e.key === "Enter" || e.key === " ") { e.preventDefault(); toggle(); }
    });
  });

  /* ── 3. copy buttons on every [data-copy] code block ──────── */
  document.querySelectorAll("[data-copy]").forEach((pre) => {
    const btn = document.createElement("button");
    btn.className = "copy-btn";
    btn.type = "button";
    btn.textContent = "Copy";
    btn.addEventListener("click", async () => {
      const text = pre.querySelector("code").innerText;
      try {
        await navigator.clipboard.writeText(text);
      } catch (e) {
        // fallback for non-secure contexts (e.g. file://)
        const ta = document.createElement("textarea");
        ta.value = text; document.body.appendChild(ta);
        ta.select(); document.execCommand("copy"); ta.remove();
      }
      btn.textContent = "Copied ✓";
      btn.classList.add("copied");
      setTimeout(() => { btn.textContent = "Copy"; btn.classList.remove("copied"); }, 1400);
    });
    pre.appendChild(btn);
  });

  /* ── 4. "should I use Fable?" decision helper ─────────────── */
  const out = document.getElementById("decider-out");
  const inputs = document.querySelectorAll("#decider-q input");
  function scoreDecider() {
    let anyChecked = false;
    let score = 0;
    let hardBlock = false;
    inputs.forEach((i) => {
      if (i.checked) {
        anyChecked = true;
        const w = Number(i.dataset.w);
        score += w;
        if (w === -3) hardBlock = true; // ZDR org = hard no
      }
    });
    const verdict = out.querySelector(".decider-verdict");
    const detail = out.querySelector(".decider-detail");
    out.classList.remove("go", "maybe", "no");

    if (!anyChecked) {
      verdict.textContent = "Pick a few boxes ☝️";
      detail.textContent = "I'll give you a recommendation.";
      return;
    }
    if (hardBlock) {
      out.classList.add("no");
      verdict.textContent = "Not yet — fix the blocker first";
      detail.textContent =
        "Fable requires 30-day data retention; under ZDR every request 400s. Until that's changed, use claude-opus-4-8.";
      return;
    }
    if (score >= 3) {
      out.classList.add("go");
      verdict.textContent = "Yes — this is Fable's sweet spot";
      detail.textContent =
        "Hard, long-horizon, quality-first work is exactly what Fable is built for. Default to effort:\"high\" (xhigh for the hardest parts), stream, and give the full task spec up front.";
    } else if (score >= 1) {
      out.classList.add("maybe");
      verdict.textContent = "Maybe — try it, but compare";
      detail.textContent =
        "It could be a good fit. Run it head-to-head against claude-opus-4-8 on your eval set and weigh the quality gain against the higher cost and the ~30% token re-baseline.";
    } else {
      out.classList.add("no");
      verdict.textContent = "Probably overkill";
      detail.textContent =
        "For high-volume, latency- or cost-sensitive, or simple tasks, a cheaper model (Opus, Sonnet, or Haiku) usually wins. Save Fable for the genuinely hard jobs.";
    }
  }
  inputs.forEach((i) => i.addEventListener("change", scoreDecider));
  scoreDecider();

  /* ── 5. quiz ──────────────────────────────────────────────── */
  const QUIZ = [
    {
      q: "You're moving an Opus call to Fable. It sets thinking.budget_tokens. What do you do?",
      opts: [
        "Lower the budget so it fits Fable's limit",
        "Remove the thinking param entirely and use output_config.effort",
        "Switch to thinking:{type:\"disabled\"} instead",
        "Leave it — budget_tokens still works on Fable",
      ],
      correct: 1,
      why: "Thinking is always on. budget_tokens and type:\"disabled\" both return 400. Steer depth with output_config.effort (low → max).",
    },
    {
      q: "Your code does print(response.content[0].text) and occasionally crashes with an index error. Why?",
      opts: [
        "Rate limiting returned an empty body",
        "The model timed out",
        "A refusal returned HTTP 200 with stop_reason:\"refusal\" and empty content",
        "max_tokens was set too low",
      ],
      correct: 2,
      why: "Safety classifiers can decline a request as a successful 200 with stop_reason:\"refusal\". Check stop_reason before reading content.",
    },
    {
      q: "Same prompt as on Opus, but you're hitting max_tokens / truncation on Fable. Most likely cause?",
      opts: [
        "Fable's new tokenizer counts ~30% more tokens for the same text",
        "Fable has a smaller context window",
        "Fable ignores max_tokens",
        "The prompt cache is corrupting the input",
      ],
      correct: 0,
      why: "The new tokenizer inflates counts ~30% vs Opus-tier. Re-baseline with count_tokens (it returns both tokenizers) — don't reuse old budgets.",
    },
    {
      q: "Best way to make Fable produce strictly-shaped JSON?",
      opts: [
        "Prefill the assistant turn with an opening brace",
        "Set temperature to 0",
        "Use output_config.format with a JSON schema",
        "Add 'RETURN ONLY JSON' three times in caps",
      ],
      correct: 2,
      why: "Assistant prefill 400s on Fable and temperature is removed. Structured outputs (output_config.format) guarantee a schema-valid response.",
    },
    {
      q: "Your carefully-tuned Opus system prompt (numbered steps, 'CRITICAL: YOU MUST…') underperforms on Fable. Fix?",
      opts: [
        "Add even more emphatic instructions",
        "Strip the step-by-step scaffolding; state the goal + constraints and let it work",
        "Lower the effort to low",
        "Split it into ten smaller prompts",
      ],
      correct: 1,
      why: "Fable follows instructions literally; over-prescription reduces quality. Give the goal and constraints up front, drop the scaffolding, and A/B it.",
    },
  ];

  const quizEl = document.getElementById("quiz");
  if (quizEl) {
    let answered = 0, correctCount = 0;
    QUIZ.forEach((item, qi) => {
      const card = document.createElement("div");
      card.className = "qcard";
      const q = document.createElement("p");
      q.className = "qq";
      q.innerHTML = `<span class="qn">Q${qi + 1}</span>${item.q}`;
      card.appendChild(q);

      const opts = document.createElement("div");
      opts.className = "qopts";
      const fb = document.createElement("p");
      fb.className = "qfb";

      item.opts.forEach((text, oi) => {
        const b = document.createElement("button");
        b.className = "qopt";
        b.type = "button";
        b.textContent = text;
        b.addEventListener("click", () => {
          if (b.disabled) return;
          const all = opts.querySelectorAll(".qopt");
          all.forEach((x) => (x.disabled = true));
          const right = oi === item.correct;
          if (right) { b.classList.add("correct"); correctCount++; }
          else {
            b.classList.add("wrong");
            all[item.correct].classList.add("correct");
          }
          fb.innerHTML = `<b>${right ? "Correct." : "Not quite."}</b> ${item.why}`;
          fb.classList.add("show");
          answered++;
          if (answered === QUIZ.length) showScore();
        });
        opts.appendChild(b);
      });

      card.appendChild(opts);
      card.appendChild(fb);
      quizEl.appendChild(card);
    });

    function showScore() {
      const s = document.createElement("div");
      s.className = "quiz-score";
      const msg =
        correctCount === QUIZ.length ? "Perfect — you're ready to ship on Fable. ❦"
        : correctCount >= 3 ? "Solid. Skim the pitfalls you missed and you're good."
        : "Worth another pass through §03 — these are the ones that bite.";
      s.textContent = `You got ${correctCount} / ${QUIZ.length}. ${msg}`;
      quizEl.appendChild(s);
      s.scrollIntoView({ behavior: "smooth", block: "nearest" });
    }
  }

  /* ── 6. back-to-top button ────────────────────────────────── */
  const toTop = document.getElementById("totop");
  if (toTop) {
    const onScroll = () => { toTop.hidden = window.scrollY < 600; };
    window.addEventListener("scroll", onScroll, { passive: true });
    onScroll();
    toTop.addEventListener("click", () => window.scrollTo({ top: 0, behavior: "smooth" }));
  }
})();
