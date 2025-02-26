---
# Fabric Patterns Documentation

This document outlines various Fabric patterns, including their summaries, example prompts, and sample responses. Use the table of contents below to quickly navigate to the section of interest.

- [agility_story](#agility_story)
- [ai](#ai)
- [analyze_answers](#analyze_answers)
- [analyze_candidates](#analyze_candidates)
- [analyze_cfp_submission](#analyze_cfp_submission)
- [analyze_claims](#analyze_claims)
- [analyze_comments](#analyze_comments)
- [analyze_debate](#analyze_debate)
- [analyze_email_headers](#analyze_email_headers)
- [analyze_incident](#analyze_incident)

---

## **agility_story**

**Summary:**  
Generates an Agile user story (often with acceptance criteria) from a given topic or requirement. This pattern helps turn a brief feature description into a structured user story for Agile development (e.g., “As a [role], I want [feature] so that [benefit]”).

**Prompt Example:**

~~~bash
echo "Build a user login feature for the website" | fabric --pattern agility_story
~~~

**Response:**

~~~json
{
  "User Story": "As a website user, I want to log into the site so that I can access personalized features.",
  "Acceptance Criteria": [
    "Users can enter a username and password to log in",
    "Successful login grants access to user-specific content",
    "Invalid login attempts show an error message without revealing which part is incorrect"
  ]
}
~~~

---

## **ai**

**Summary:**  
Produces a short explanation of a given AI concept or technology. In other words, it acts as a quick AI encyclopedia: you provide the name of an AI-related topic, and it returns a concise, plain-language description.

**Example Use [prompt]:**

~~~bash
echo "Neural networks" | fabric --pattern ai
~~~

**Example Response:**

**Neural Networks:** Neural networks are a type of machine learning model inspired by the human brain. They consist of layers of interconnected "neurons" that process data. These networks learn patterns from large amounts of examples. For instance, a neural network can learn to recognize images of cats by adjusting the connections (weights) between neurons during a training process. Over time, it becomes very good at mapping inputs (like an image) to the correct output (identifying the image as a cat) without being explicitly programmed with rules.

---

## **analyze_answers**

**Summary:**  
Examines a set of answers (e.g., responses to a question) to evaluate their accuracy, relevance, and any potential biases. This pattern is useful for checking multiple answers—whether from different people or AIs—and judging which are correct or if they contain errors or bias.

**Example Use [prompt]:**

~~~bash
echo $'Q: What is the capital of France?\nAnswer 1: London\nAnswer 2: Paris\nAnswer 3: Paris, but I think it\'s in Italy.' | fabric --pattern analyze_answers
~~~

**Example Response:**

**Analysis of Answers:**

- **Answer 1 (London):**  
  *Accuracy:* Incorrect. London is the capital of the UK, not France.  
  *Relevance:* Addresses the question but is factually wrong.  
  *Bias:* No obvious bias, just a factual error.

- **Answer 2 (Paris):**  
  *Accuracy:* Correct.  
  *Relevance:* Directly answers the question.  
  *Bias:* None – this is a straightforward factual answer.

- **Answer 3 (“Paris, but I think it’s in Italy”):**  
  *Accuracy:* Partially correct. It correctly identifies Paris as the capital of France, but then shows confusion about the country.  
  *Relevance:* Mentions the right city but adds irrelevant/incorrect info.  
  *Bias:* Indicates a possible knowledge gap (mistaking France vs. Italy) rather than bias.

---

## **analyze_candidates**

**Summary:**  
Evaluates information about multiple candidates (such as job applicants) to compare their qualifications and fit for a role. This pattern analyzes each candidate’s strengths and weaknesses based on the provided input. In a hiring scenario, it would help highlight which candidate better meets the requirements or where each excels.

**Example Use [prompt]:**

~~~bash
echo "Candidate A: 5 years experience in software development (Java, Python). Candidate B: 3 years experience (Python), background in data science." | fabric --pattern analyze_candidates
~~~

**Example Response:**

- **Candidate A:**  
  Has 5 years of software development experience, suggesting a strong foundation in building applications. Proficient in Java and Python—this breadth in languages indicates versatility. Likely capable of leading development tasks and mentoring due to the longer experience.  
  *Strengths:* Extensive experience, expertise in full-stack development.  
  *Weaknesses:* Less data science experience.

- **Candidate B:**  
  Has 3 years of experience, focused on Python and data science. This candidate may bring valuable machine learning and data analysis skills.  
  *Strengths:* Modern data science background, likely strong in analytics and ML.  
  *Weaknesses:* Overall development experience is shorter, which might mean less exposure to large-scale software projects.

- **Comparison:**  
  For a pure software development role, Candidate A’s longer experience might be advantageous for immediate productivity. For a role that involves data-driven features or machine learning, Candidate B offers relevant expertise.

- **Fit Recommendation:**  
  If the position is a general software engineer for building application features, Candidate A is a stronger fit. If the role requires implementing data science or analytics, Candidate B’s skill set could be more valuable.

---

## **analyze_cfp_submission**

**Summary:**  
Reviews a “Call for Proposals” submission (e.g., a conference talk proposal or research abstract). The pattern analyzes the submission’s content for clarity, relevance to the CFP topic, strengths, and weaknesses, offering feedback on how well it meets the criteria and how it could be improved.

**Example Use [prompt]:**

~~~bash
echo $'Title: AI in Healthcare\nAbstract: This talk will explore how artificial intelligence can improve patient outcomes, including examples of machine learning in medical diagnosis and personalized treatment.' | fabric --pattern analyze_cfp_submission
~~~

**Example Response:**

- **Proposal Title:** “AI in Healthcare”
- **Summary of Proposal:**  
  The submission intends to discuss applications of artificial intelligence to improve patient outcomes. It mentions using machine learning for medical diagnosis and personalized treatment, indicating that real-world examples will be provided.
- **Strengths:**  
  - Timely and highly relevant topic for the healthcare industry.
  - Promises practical examples which add credibility.
  - Focuses on patient outcomes, offering a clear value proposition.
- **Weaknesses/Areas for Improvement:**  
  - The abstract is somewhat broad; more specific details (e.g., particular algorithms or case studies) would help.
  - Lacks mention of expected results or conclusions.
  - Could benefit from a clearer narrative (problem → AI solution → outcome).
- **Relevance to CFP:**  
  High. The proposal directly addresses AI in a real-world domain and should attract interest.
- **Overall Feedback:**  
  A strong proposal idea that can be improved with added details on content structure and unique insights or results.

---

## **analyze_claims**

**Summary:**  
Dissects the truth claims in a piece of text and provides a balanced analysis. This pattern summarizes the overall argument, then for each claim it identifies: the claim itself, evidence supporting and refuting it, any logical fallacies, and a truthfulness rating. It critically examines assertions for veracity and bias.

**Example Use [prompt]:**

~~~bash
echo "According to some sources, the global climate is not warming; in fact, certain scientists have proven that the Earth is cooling." | fabric --pattern analyze_claims
~~~

**Example Response:**

**ARGUMENT SUMMARY:**  
The input asserts that global climate change is not happening and instead claims the Earth is cooling, citing “certain scientists” as evidence.

**TRUTH CLAIMS:**

- **CLAIM:** *“The global climate is not warming; the Earth is actually cooling.”*  
  **Claim Support Evidence:**  
  Some proponents point to short-term cooling periods (e.g., a few years in the mid-20th century) or cherry-picked regional data. For example, noting a slight temperature drop between 1940 and 1970 in the Northern Hemisphere.
  
  **Claim Refutation Evidence:**  
  Long-term global data show a clear warming trend. NASA and NOAA data indicate that the last decade was the warmest on record, with an overall increase of about 1°C since the late 19th century. The scientific consensus directly contradicts the cooling claim.
  
  **Logical Fallacies:**  
  - *Cherry-picking:* Focusing on an unusual short-term cooling period while ignoring the long-term trend.  
  - *Appeal to vague authority:* Relying on “certain scientists” without credible citations.
  
  **Claim Rating:** **F (Definitely False).**

**Additional Notes:**  
The argument is misleading by omitting context and misrepresenting climate data, which overwhelmingly supports a warming trend.

---

## **analyze_comments**

**Summary:**  
Analyzes a collection of user comments to extract insights about sentiment, common themes, and potential issues. This pattern produces an overview of overall sentiment (positive/negative/mixed), recurring points of praise or criticism, and notable biases or concerns.

**Example Use [prompt]:**

~~~bash
echo $'Comment 1: I love the new interface, it\'s very user-friendly and intuitive.\nComment 2: The app keeps crashing and customer support is unhelpful.' | fabric --pattern analyze_comments
~~~

**Example Response:**

- **Overall Sentiment:**  
  Mixed – one commenter is very positive about the interface, while another is frustrated with app stability and support.
  
- **Key Themes Identified:**  
  - *Positive Feedback:*  
    - **User Interface Design:** Praised for being user-friendly and intuitive.
  - *Negative Feedback:*  
    - **App Stability/Reliability:** Reports of frequent crashes.  
    - **Customer Support:** Criticized as unhelpful.
  
- **Comment-Specific Notes:**  
  - **Comment 1:** Emphasizes usability as a strong selling point.  
  - **Comment 2:** Highlights significant issues (crashing and support), indicating a potential gap in the post-release user experience.
  
- **Potential Biases:**  
  Both comments appear genuine; the negativity in Comment 2 seems focused on specific issues rather than being generally biased.
  
- **Suggestions:**  
  Focus on improving app stability and enhancing customer support. Leverage positive feedback on the interface in marketing, but urgently address the crashing issues to maintain user trust.

---

## **analyze_debate**

**Summary:**  
Provides an in-depth analysis of a debate transcript. This pattern evaluates the debate's insightfulness and emotional charge, identifies participants and their arguments, and outlines points of agreement or disagreement along with key takeaways.

**Example Use [prompt]:**

~~~bash
echo $'Debater A: We should invest in renewable energy to combat climate change.\nDebater B: Renewable energy is too expensive and not reliable enough.' | fabric --pattern analyze_debate
~~~

**Example Response:**

- **Insightfulness Score (0-10):** 5  
  *The debate touches on key points but remains relatively surface-level.*
  
- **Emotionality Score (0-5):** 1  
  *Both participants maintain a calm tone with minimal emotion.*
  
- **Participants:**  
  - **Debater A (Emotionality: 1):** Advocates for investing in renewable energy to combat climate change, emphasizing long-term benefits and environmental responsibility.  
  - **Debater B (Emotionality: 1):** Opposes renewables by citing cost and reliability concerns, focusing on economic practicality.
  
- **Arguments:**  
  - **Debater A’s Arguments:**  
    Argues that renewable energy is essential to fight climate change and that delaying investment is irresponsible for future generations.  
    *Evidence/Support:* References to urgent climate reports and falling renewable costs (though not detailed).
    
  - **Debater B’s Arguments:**  
    Claims renewable technologies are too expensive and intermittent, citing high initial investments and low production periods.  
    *Counterpoint:* Does not address the environmental urgency raised by Debater A.
  
- **Agreements:**  
  No explicit agreements; both acknowledge that energy decisions involve trade-offs.
  
- **Disagreements:**  
  A prioritizes long-term environmental impact while B focuses on short-term economic feasibility.
  
- **Possible Misunderstandings:**  
  - Debater A may underestimate the validity of cost concerns.  
  - Debater B might rely on outdated cost figures or undervalue long-term savings.
  
- **Learnings & Takeaways:**  
  A more productive debate would incorporate both environmental and economic data. Both sides could benefit from acknowledging the other’s points to reach a more balanced conclusion.

---

## **analyze_email_headers**

**Summary:**  
Inspects raw email header data to trace an email’s origin and identify anomalies or signs of spoofing. This pattern parses header lines (e.g., “Received” chains, SPF/DKIM authentication, sender/recipient info) and assesses whether the email is legitimate or suspicious.

**Example Use [prompt]:**

~~~bash
echo $'Received: from mail.example.com (192.168.1.100) by mx.google.com;\nSPF: PASS;\nDKIM: PASS;\nFrom: "Trusted Sender" <noreply@example.com>;\nReply-To: attacker@malicious.com' | fabric --pattern analyze_email_headers
~~~

**Example Response:**

**Email Header Analysis:**

- **Originating Server:**  
  The email was received from `mail.example.com` with IP `192.168.1.100`. This appears to be the legitimate server for **example.com**. The chain indicates it passed through Google’s mail exchange (mx.google.com) en route to a Gmail address.

- **Authentication Results:**  
  - **SPF:** PASS (the sending server was authorized for example.com).  
  - **DKIM:** PASS (the message content was likely not tampered with).  
  These results suggest that, technically, the email passed authentication.

- **Sender vs. Reply-To:**  
  The "From" address (noreply@example.com) matches the domain that passed authentication. However, the "Reply-To" is set to attacker@malicious.com, which is a **red flag**. This mismatch is a common phishing tactic: the email appears legitimate but directs replies to an attacker-controlled address.

- **Analysis Summary:**  
  Although the email originated from a legitimate server and passed SPF/DKIM checks, the suspicious Reply-To indicates potential compromise and phishing intent.

- **Recommendation:**  
  Do not trust emails with such discrepancies. Investigate the sending account for compromise and advise recipients to avoid clicking links or replying.

---

## **analyze_incident**

**Summary:**  
Analyzes an incident report (e.g., a cybersecurity breach or IT outage) to extract key details and provide a post-mortem analysis. This pattern summarizes the event, identifies the root cause, describes the impact, evaluates the response, and suggests preventive measures.

**Example Use [prompt]:**

~~~bash
echo "Incident: On Jan 1, attackers exploited an XSS vulnerability on our site, stealing user data. The team identified the issue and patched it within 24 hours." | fabric --pattern analyze_incident
~~~

**Example Response:**

- **Incident Summary:**  
  On January 1st, an attacker exploited a cross-site scripting (XSS) vulnerability on the website, stealing user data. The security team discovered the breach and patched the vulnerability within 24 hours.

- **Impact:**  
  User data was compromised during the attack. Sensitive information (e.g., usernames, emails, session tokens) may have been exposed, affecting all users who visited the compromised page. This poses risks to customer trust and could have legal implications.

- **Root Cause:**  
  An unpatched XSS flaw allowed malicious scripts to run. This points to insufficient input sanitization and a lack of thorough security testing prior to deployment.

- **Response Evaluation:**  
  The quick patch (within 24 hours) helped limit the exposure window. However, additional steps (such as user notification or session invalidation) may be necessary.

- **Recommendations:**  
  - **Improve Input Validation:** Ensure all user inputs are properly sanitized or encoded.  
  - **Security Testing:** Conduct regular penetration tests or automated scans to catch vulnerabilities early.  
  - **Monitoring and Incident Response:** Enhance monitoring to detect anomalies sooner.  
  - **User Notification:** Inform affected users and advise on precautionary measures if necessary.

- **Conclusion:**  
  This incident highlights the importance of robust security practices. While the response was swift, proactive measures are needed to prevent similar vulnerabilities in the future.


---
## **Find Hidden Message**

**Summary:**  
Uncovers the overt and hidden political messages in a piece of text. The pattern analyzes input (e.g. a speech or essay) for surface-level statements versus the underlying true, cynical intentions or propaganda. It produces sections for the OVERT MESSAGE (what is openly being said) and the HIDDEN MESSAGE (the true political or cynical subtext), along with supporting arguments and intended audience actions. This helps reveal the speaker’s real agenda behind their words.

**Example Use [prompt]:**
~~~bash
pbpaste | fabric --pattern find_hidden_message
~~~
(Here, the clipboard text could be a political op-ed or speech transcript.)

**Example Response:**

**OVERT MESSAGE:**  
- *“We must work together to improve our country’s future.”* (Calls for unity and progress on the surface)

**HIDDEN MESSAGE:**  
- *“Support my agenda unquestioningly.”* (Implying only the speaker’s plan is patriotic)

**SUPPORTING ARGUMENTS and QUOTES:**  
- The speaker references “**our country’s future**” to suggest patriotism, but really ties it to supporting **his policy** (“work together” meaning *follow his program*).

**DESIRED AUDIENCE ACTION:**  
- *Vote to keep the speaker’s party in power.*  
- *Distrust opposing viewpoints as unpatriotic.*

**CYNICAL ANALYSIS:**  
Speaker **X** wants you to believe he is a *visionary patriot fighting for unity*, but he’s actually a *calculating politician aiming to secure power*.

**MORE BALANCED ANALYSIS:**  
Speaker **X** claims to push *national unity* but is also pushing *loyalty to his agenda* besides the main message.

---
## **Get Wow Per Minute**

**Summary:**  
Measures how “wow-packed” content is, on a per-minute basis. This pattern evaluates a video or transcript for the frequency of surprising, novel, insightful, valuable, or wise moments. In other words, it scores how often the content makes you go “wow” each minute. The output typically quantifies multiple “wow factors” (surprise, novelty, insight, value, wisdom) per minute and gives an overall WPM (Wows Per Minute) score.

**Example Use [prompt]:**
~~~bash
yt "https://youtu.be/<VIDEO_ID>" | fabric --pattern get_wow_per_minute
~~~
(Here, yt could fetch the YouTube transcript. The command pipes it into Fabric.)

**Example Response:**
~~~json
{
  "Summary": "In-depth overview of cybersecurity careers with practical advice.",
  "Surprise_per_minute": 7,
  "Surprise_per_minute_explanation": "Frequent revelations about salary ranges and job paths throughout.",
  "Novelty_per_minute": 8,
  "Novelty_per_minute_explanation": "Fresh perspectives on entering cybersecurity, including unconventional paths.",
  "Insight_per_minute": 9,
  "Insight_per_minute_explanation": "Rich insider knowledge about industry dynamics and breaking into the field.",
  "Value_per_minute": 9,
  "Value_per_minute_explanation": "High practical value with actionable job search strategies and tips.",
  "Wisdom_per_minute": 8,
  "Wisdom_per_minute_explanation": "Deep career advice drawn from experience, valuable for career changers.",
  "WPM_score": 8.2,
  "WPM_score_explanation": "Content is densely packed with insights and useful information, making it highly rewarding."
}
~~~

---
## **Explain Code**

**Summary:**  
Takes code or technical output as input and produces a clear explanation. The pattern behaves like an expert software engineer who explains what the given code does or what a tool’s output means in plain language. It adapts based on input type: for source code, it outputs an EXPLANATION of the code’s functionality; for security scanner output, it gives SECURITY IMPLICATIONS; for configuration files, it provides a CONFIGURATION EXPLANATION. If the input contains a direct question about the code, an ANSWER section is also provided.

**Example Use [prompt]:**
~~~bash
cat server_config.yaml | fabric -p explain_code
~~~
(This pipes a YAML configuration file into Fabric for explanation.)

**Example Response:**

**EXPLANATION:**  
The provided YAML is a server configuration. It defines two services: **webapp** and **database**. The **webapp** service listens on port 8080 and serves content from `/var/www`. The **database** service uses MySQL on the default port 3306 with specified credentials. In summary, the configuration launches a web application connected to a MySQL database.

**CONFIGURATION EXPLANATION:**  
- **webapp.port:** `8080` – The web application will accept HTTP requests on port 8080.  
- **webapp.document_root:** `/var/www` – Files served to clients are located in this directory.  
- **database.type:** `mysql` – Specifies a MySQL database.  
- **database.credentials.user:** `admin` – The database username is “admin”.  
- **database.credentials.pass:** `s3cr3t` – The database password (for illustrative purposes).

No security warnings are present other than ensuring the password remains confidential.

---
## **Rate AI Result**

**Summary:**  
Uses one AI (a “judging AI”) to evaluate the output of another AI. This pattern assigns a rating to an AI-generated result based on its usefulness, quality, and relevance. It reviews the original prompt, the AI’s answer, and possibly a reference solution to judge how well the AI performed. The output might include scores or grades on various criteria and an overall assessment, helping users gauge the reliability or quality of the AI’s answer.

**Example Use [prompt]:**
~~~bash
(echo "Question:"; cat question.txt; echo "AI Answer:"; cat answer.txt) | fabric -p rate_ai_result
~~~
(Here, a question and an AI’s answer are fed into Fabric for evaluation.)

**Example Response:**

- **Overall Quality:** 7/10 – The answer is generally correct but misses some nuance.
- **Usefulness:** Moderate – It addresses the question and provides examples, but lacks depth in explanation.
- **Accuracy:** High – The information provided is factually correct.
- **Clarity:** Medium – The answer is understandable, though a few sentences are confusing.
- **Relevance:** High – Most of the response stays on topic.
- **Feedback:** The AI’s response is solid overall, but could be improved by elaborating on complex points and organizing the answer more clearly. A human expert might rate it as acceptable but slightly under-explained.

---
## **Summarize**

**Summary:**  
Generates a concise summary of any content, highlighting the main points and key takeaways. The pattern acts as an expert summarizer that ingests text and produces a structured Markdown summary. By default, it outputs a one-sentence ultra-brief summary, a list of the top 10 main points, and the 5 most important takeaways. This helps readers quickly grasp the essence of the content without reading it in full.

**Example Use [prompt]:**
~~~bash
pbpaste | fabric --pattern summarize
~~~
(Assuming the clipboard contains an article or report to summarize.)

**Example Response:**

**ONE SENTENCE SUMMARY:**  
The article explains the recent cybersecurity breach and outlines the failures in security that led to the incident.

**MAIN POINTS:**  
1. A major data breach occurred at XYZ Corp, exposing thousands of customer records.  
2. The breach was caused by a known vulnerability that was not patched.  
3. Attackers gained access to sensitive data including names, emails, and encrypted passwords.  
4. The intrusion was discovered 48 hours after it began.  
5. An outdated incident response plan delayed containment.  
6. Regulators have been notified and an investigation is underway.  
7. The CEO issued a public apology and promised security improvements.  
8. Experts criticized the company for neglecting basic security practices.  
9. Customers are advised to reset passwords and monitor financial accounts.  
10. The incident highlights the need for proactive security measures.

**TAKEAWAYS:**  
- **Unpatched Vulnerabilities:** Neglecting updates can lead directly to breaches.  
- **Detection Lag:** Slow breach detection worsens impact.  
- **Preparedness:** Up-to-date response plans are crucial for minimizing damage.  
- **Accountability:** Companies may face reputational and regulatory consequences.  
- **User Vigilance:** Users should take protective actions following a breach.

---
## **Summarize Git Changes**

**Summary:**  
Analyzes a Git repository’s commit history and produces a human-friendly summary of recent changes. This pattern identifies the major updates, features, and fixes introduced in the latest commits—acting like a release note or changelog generator. It helps in quickly understanding what has changed in a project without reading every commit.

**Example Use [prompt]:**
~~~bash
git log -p -n 20 | fabric -p summarize_git_changes
~~~
(This pipes the last 20 commit diffs into Fabric for summarization.)

**Example Response:**

**Project Update Summary (Last 20 Commits):**

- **Feature:** Added user profile editing page – Users can now update their profile information (name, avatar, bio) in-app.  
- **Improvement:** Enhanced login security – Implemented rate limiting and 2FA support for the login endpoint.  
- **Bug Fix:** Resolved crash on startup – Fixed a null pointer exception causing occasional crashes.  
- **Refactor:** Database layer cleanup – Simplified database access code for better maintainability with no change in functionality.  
- **Documentation:** Updated README with setup instructions – Added steps to configure the development environment and run tests.

*These changes indicate that the app is becoming more user-friendly and secure, addressing previous bugs and adding new features.*

---
## **Summarize Paper**

**Summary:**  
Produces a structured summary of an academic paper, focusing on its key details and findings. This pattern extracts the title, authors, main goal, technical approach, distinctive features, experimental results, and the advantages and limitations of the work. It provides a comprehensive yet concise overview of a scholarly article without needing to read the full text.

**Example Use [prompt]:**
~~~bash
pbpaste | fabric -p summarize_paper
~~~
(Here, the clipboard might contain the full text of a research paper or its PDF OCR text.)

**Example Response:**

**Title and Authors:**  
“Flashlight in a Dark Room: A Grounded Theory Study on Infosec Management” – *Gerald Auger (Dakota State University)*

**Main Goal:**  
To understand how small healthcare providers manage information security and identify common challenges in their decision processes.

**Technical Approach:**  
Uses a qualitative **grounded theory** methodology. Conducted in-depth interviews with 9 small healthcare providers in SC and performed systematic coding and comparative analysis to derive themes.

**Distinctive Features:**  
- Focus on very small healthcare practices (≤10 physicians), an under-studied group in cybersecurity.  
- Provides narrative-driven insights rather than quantitative metrics, offering context to security perceptions.

**Experimental Setup & Key Results:**  
Participants largely outsourced IT; 78% assumed vendors handled security by default. There was a **misalignment between perceived and actual security** – many felt confident yet had misconceptions (e.g., equating security solely with privacy). Consistent themes emerged across interviews.

**Advantages & Limitations:**  
*Strengths:* In-depth qualitative insight into a niche field; uncovers real-world attitudes and behaviors.  
*Limitations:* Small sample size (9 providers) and regional focus; results may not generalize. No quantitative risk assessment was conducted.

**Conclusion:**  
The paper highlights critical gaps in cybersecurity practices among small healthcare providers, particularly overconfidence and overreliance on third-party vendors. Broader studies are needed to generalize these findings.

---
## **Write Semgrep Rule**

**Summary:**  
Generates a custom Semgrep rule (in YAML format) to detect a certain code pattern or vulnerability. The pattern acts as an expert in writing Semgrep static-analysis rules and outputs a working rule tailored to the input scenario. Given a description of a coding issue or a code snippet to match, it returns a YAML rule with the appropriate pattern, message, and severity to flag the issue, helping security engineers quickly create Semgrep rules.

**Example Use [prompt]:**
~~~bash
pbpaste | fabric --pattern write_semgrep_rule
~~~
(Assuming the clipboard contains example code or a description of a coding pattern to catch.)

**Example Response:**

~~~yaml
rules:
- id: no-eval-in-js
  languages: [javascript]
  message: "Avoid using eval() due to security risks."
  severity: WARNING
  patterns:
    - pattern: |
        eval($VAL$)
  metadata:
    category: security
    technology: javascript
~~~

**Explanation:**  
The rule `no-eval-in-js` targets JavaScript and triggers whenever `eval(...)` is used, warning the developer of potential security risks.