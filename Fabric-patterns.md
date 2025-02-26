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

---
## **Analyze Threat Report**

**Summary:**  
The analyze_threat_report pattern digests a comprehensive cybersecurity threat report and pulls out its most valuable information. It produces a one-sentence summary of the report’s key finding, followed by a list of major trends and notable statistics mentioned in the report. In short, it automates the extraction of juicy bits – e.g. prominent attack trends, significant figures, and other critical insights – from lengthy threat intelligence documents.

**Best Use Cases:**  
Use this pattern when you have a large annual or quarterly threat intelligence report (such as Verizon DBIR or a CrowdStrike threat report) and need a quick distillation of its essence. It’s ideal for security analysts or executives who want to glean key takeaways (trends, stats, highlights) without reading the full report. This is useful for creating summaries for presentations or briefings and prioritizing which parts of the report to read in depth.

**Example Use [prompt]:**  
For example, if you have the CrowdStrike 2024 Global Threat Report saved as crowdstrike2024.txt, you could run:

~~~bash
fabric -p analyze_threat_report < crowdstrike2024.txt
~~~

The pattern will then output a structured summary of that report.

**Example Response:**  
After analyzing the CrowdStrike 2024 Global Threat Report, the output might be:

- **ONE-SENTENCE-SUMMARY:**  
  The 2024 CrowdStrike Global Threat Report highlights the accelerated pace and sophistication of cyberattacks, emphasizing the critical need for advanced, AI-driven cybersecurity measures in the face of evolving threats. [oai_citation_attribution:3‡danielmiessler.com](https://danielmiessler.com/blog/fabric-pattern-analyze-threat-report#:~:text=ONE)
  
- **TRENDS:**  
  - Generative AI lowers the entry barrier for cyberattacks, enabling more sophisticated threats. [oai_citation_attribution:4‡danielmiessler.com](https://danielmiessler.com/blog/fabric-pattern-analyze-threat-report#:~:text=TRENDS%3A)  
  - Identity-based attacks and social engineering are increasingly central to adversaries' strategies. [oai_citation_attribution:5‡danielmiessler.com](https://danielmiessler.com/blog/fabric-pattern-analyze-threat-report#:~:text=,increasingly%20central%20to%20adversaries%27%20strategies)
  
- **STATISTICS:**  
  - 34 new adversaries tracked by CrowdStrike, raising the total to 232. [oai_citation_attribution:6‡danielmiessler.com](https://danielmiessler.com/blog/fabric-pattern-analyze-threat-report#:~:text=,on%20eCrime%20dedicated%20leak%20sites)  
  - Cloud-conscious cases increased by 110% year over year (YoY). [oai_citation_attribution:7‡danielmiessler.com](https://danielmiessler.com/blog/fabric-pattern-analyze-threat-report#:~:text=,year%20over%20year%20%28YoY)

**Insights on Usage:**  
This pattern excels at quickly summarizing lengthy threat reports, saving analysts considerable time. To get the best results, feed it the full text of a well-structured threat report (including sections on trends and stats, if available) and double-check any numbers or facts in the output against the source report. Overall, analyze_threat_report is a powerful tool for turning dense threat intel into an executive-friendly summary.

---

## **Analyze Threat Report Trends**

**Summary:**  
The analyze_threat_report_trends pattern focuses specifically on extracting a thorough list of emerging trends and noteworthy insights from a threat report. It behaves like an insight miner by reading the report and pulling out up to dozens of interesting or surprising findings, all aggregated under a “TRENDS” section. Unlike the broader analyze_threat_report pattern, this one omits the one-liner and stats – instead, it emphasizes a deeper dive into patterns and trends, ensuring at least 20 distinct insight points are identified.

**Best Use Cases:**  
This pattern is best when you want a comprehensive list of takeaways or discussion points from a threat report, such as during an in-depth analysis session or when writing a detailed review. It’s particularly useful for researchers or security strategists who need to identify every significant trend or highlight from a report.

**Example Use [prompt]:**  
For instance, to extract trends from the CrowdStrike report, you could run:

~~~bash
fabric -p analyze_threat_report_trends < crowdstrike2024.txt
~~~

This will output a list of trend insights found in the report.

**Example Response:**  
An output might look like:

- **TRENDS:**  
  - A significant rise in supply chain attacks, exploiting trusted software for maximum impact. [oai_citation_attribution:10‡danielmiessler.com](https://danielmiessler.com/blog/fabric-pattern-analyze-threat-report#:~:text=,the%20detection%20of%20malicious%20activities)  
  - Stealth tactics are increasingly employed to evade detection and move laterally within networks. [oai_citation_attribution:11‡danielmiessler.com](https://danielmiessler.com/blog/fabric-pattern-analyze-threat-report#:~:text=,cryptocurrency%20theft%20and%20intelligence%20collection)  
  - The growing use of cloud-conscious techniques by adversaries to exploit cloud vulnerabilities.

**Insights on Usage:**  
Be prepared for a voluminous output – this pattern is tuned to find as many insights as possible (up to 50). It’s incredibly useful for creating exhaustive checklists of findings or for research purposes, but may generate repetitive points if the input text is short. Use it on comprehensive, data-rich reports to ensure you capture all significant trends.

---

## **Answer Interview Question**

**Summary:**  
The answer_interview_question pattern helps craft well-structured, articulate answers to interview questions. It takes a prompt (typically an interview question or topic) and responds as a knowledgeable candidate might, using professional language to provide a concise but impactful answer.

**Best Use Cases:**  
This pattern is perfect for job seekers preparing for interviews. If you’re unsure how to answer a commonly asked question (e.g., “What is your greatest strength?” or “Tell me about a time you faced a challenge”), you can use this pattern to generate a strong example answer. It’s also useful for practicing and refining your own responses.

**Example Use [prompt]:**  
For example:

~~~bash
fabric -p answer_interview_question "Can you describe a situation where you had to overcome a significant obstacle at work?"
~~~

The pattern will then generate a thoughtful answer.

**Example Response:**  
An output might be:

"Absolutely. In my previous role as a project coordinator, we encountered a major obstacle when our lead developer suddenly left in the middle of a critical project. **Situation:** We were weeks away from a product launch, and losing a key team member jeopardized our timeline. **Task:** I convened an emergency meeting to redistribute tasks, brought a former intern up to speed, and worked extra hours to cover the gaps. **Action:** I maintained constant communication with stakeholders through daily updates to manage expectations. **Result:** We launched on time with a quality product. This experience taught me the importance of proactive communication and adaptable leadership under pressure."

**Insights on Usage:**  
Providing additional context (such as the field or role) can tailor the answer more closely to your situation. Use the AI-generated response as a template to structure your own answer, ensuring you incorporate your personal experiences.

---

## **Ask Secure by Design Questions**

**Summary:**  
The ask_secure_by_design_questions pattern serves as a secure design advisor for any system or component you describe. Given an input outlining a software application, system architecture, or physical project, it generates an overview of why security is critical and produces a list of Secure by Design recommendations.

**Best Use Cases:**  
Use this pattern during the early stages of system design or architecture review to ensure you’ve covered fundamental security considerations. It’s ideal for designing web applications, IoT devices, or any system where security is a concern.

**Example Use [prompt]:**  
For example, if you’re developing a smart home door lock that can be controlled via a mobile app and Bluetooth, you might run:

~~~bash
fabric -p ask_secure_by_design_questions <<EOT
We are developing a smart home door lock that can be controlled via a mobile app and Bluetooth.
EOT
~~~

**Example Response:**  
The output might be:

- **OVERVIEW:**  
  The description outlines a Bluetooth-enabled smart home door lock controlled by a mobile app, highlighting the need to secure both device communication and user authentication.

- **SECURE BY DESIGN RECOMMENDATIONS:**  
  - **Encrypted Communication:** Ensure all data transmitted between the lock and the mobile app/server is encrypted.  
  - **Strong Authentication:** Implement robust, multi-factor authentication before granting access.  
  - **Firmware Security:** Use signed firmware updates and secure boot processes to prevent unauthorized code execution.  
  - **Fail-Safe Modes:** Design the lock to fail securely in the event of errors or power loss.  
  - **Privacy by Design:** Minimize data collection and protect any stored credentials.

**Insights on Usage:**  
This pattern provides a checklist of security measures tailored to your system description. Its effectiveness depends on how detailed your input is, so be clear about the system’s functionality and context.

---

## **Ask Uncle Duke**

**Summary:**  
The ask_uncle_duke pattern provides answers and advice in the persona of “Uncle Duke” – an outspoken, no-nonsense character with a wealth of experience and a touch of humor. When you ask Uncle Duke a question, you get a candid, witty response with personality.

**Best Use Cases:**  
This pattern is ideal for informal or creative scenarios. Use it for life advice, overcoming writer’s block, or simply for a fun and engaging perspective. It’s not intended for strictly professional guidance but rather for colorful, conversational advice.

**Example Use [prompt]:**  
For example:

~~~bash
fabric -p ask_uncle_duke "Uncle Duke, what’s your secret to staying motivated when projects get tough?"
~~~

**Example Response:**  
The output might be:

"Uncle Duke: Well, kid, staying motivated is like keeping a fire going in a rainstorm. You shield that fire with whatever you’ve got. For me, it meant remembering why I lit the flame in the first place. When projects get tough, I hunker down, pour myself a black coffee (or something stronger on rough days), and get back to work. The secret is: don’t wait for motivation to strike – do the work, and the satisfaction will stoke that fire. And if all else fails, imagine the look on everyone’s faces when you pull it off."

**Insights on Usage:**  
This pattern is best used in casual contexts where a light-hearted, candid response is appropriate. It delivers advice with personality, making interactions more engaging.

---

## **Capture Thinkers Work**

**Summary:**  
The capture_thinkers_work pattern creates a distilled profile of a given thinker, author, or philosopher by capturing the essence of their contributions. It typically includes background information, main ideas or theories, and notable works, providing a concise overview of the individual’s intellectual legacy.

**Best Use Cases:**  
This pattern is perfect for quickly learning about or reminding yourself of influential figures in academia, literature, science, or philosophy. It’s useful for creating study guides or quick reference notes.

**Example Use [prompt]:**  
For example:

~~~bash
echo "Hayek" | fabric -p capture_thinkers_work
~~~

**Example Response:**  
An output for “Hayek” might be:

- **Background:**  
  Friedrich August von Hayek was an Austrian-British economist and philosopher known for his defense of classical liberalism and free-market capitalism.

- **Main Ideas:**  
  Hayek emphasized the role of decentralized decision-making and the price mechanism in efficiently allocating resources, and he criticized centralized planning.

- **Notable Works:**  
  *The Road to Serfdom*, *The Constitution of Liberty*, and *Law, Legislation and Liberty*.

- **Legacy:**  
  His work laid the foundation for modern free-market economic thought and has influenced policies favoring deregulation and privatization.

**Insights on Usage:**  
The accuracy of the output depends on how well-known the figure is. For prominent thinkers, the summary is usually reliable; always verify key details when using the information for scholarly purposes.

---

## **Check Agreement**

**Summary:**  
The check_agreement pattern evaluates whether two pieces of content are in agreement with each other. It acts as a consistency or fact-checking tool by comparing a statement (or claim) with corresponding evidence or another statement, and then determines if they align.

**Best Use Cases:**  
This pattern is useful for fact-checking, verifying that a summary matches an original text, or comparing a user’s answer to an official answer key. It’s a great tool for educators, editors, or anyone needing to validate content consistency.

**Example Use [prompt]:**  
For example:

~~~bash
echo -e "Claim: The software is completely secure.\nEvidence: The software was breached last week due to a vulnerability." | fabric -p check_agreement
~~~

**Example Response:**  
An output might be:

"The evidence directly contradicts the claim. The claim states the software is 'completely secure,' but the evidence describes a breach, indicating the software was not fully secure. Therefore, they do not agree."

**Insights on Usage:**  
Ensure you provide the inputs in a clear, parseable format (for instance, by labeling with “Claim:” and “Evidence:”). The pattern checks logical agreement rather than factual truth, so it will indicate agreement even if both statements are false but consistent.

---

## **Clean Text**

**Summary:**  
The clean_text pattern is a utility that sanitizes and formats text by removing noise, unwanted characters, or markup. It strips away HTML tags, excessive whitespace, special characters, and other clutter, leaving you with cleaner, plain text.

**Best Use Cases:**  
Use clean_text whenever you have messy input, such as text copied from PDFs or websites that contains broken line breaks, HTML entities, or other artifacts. It’s often used as a preparatory step before further analysis or summarization.

**Example Use [prompt]:**  
For example:

~~~bash
fabric -p clean_text "Hello!!! *** This   is a <b>TEST</b> --- of the text-cleaning pattern..."
~~~

**Example Response:**  
The output might be:

Hello! This is a TEST of the text-cleaning pattern...

**Insights on Usage:**  
While effective at removing clutter, the pattern may be aggressive and remove desired formatting. It’s best used on prose or free-form text, and can be paired with other patterns to improve overall processing.

---

## **Coding Master**

**Summary:**  
The coding_master pattern acts as an expert software developer assistant. It understands coding-related queries and produces helpful programming output—whether that’s writing code, explaining code, or improving code. It adapts based on your prompt to provide code snippets, explanations, or debugging help.

**Best Use Cases:**  
This pattern is incredibly useful for developers and learners. Use it when you need quick code generation, debugging help, or a clear explanation of code or programming concepts. It’s ideal for writing functions, explaining algorithms, or refining code snippets.

**Example Use [prompt]:**  
For example:

~~~bash
fabric -p coding_master "Write a Python function to check if a number is prime."
~~~

**Example Response:**  
The output might be:

~~~python
def is_prime(n):
    """Check if a number is prime."""
    if n < 2:
        return False
    for i in range(2, int(n**0.5) + 1):
        if n % i == 0:
            return False
    return True
~~~

Explanation: This function first rules out numbers less than 2 (which are not prime). It then iterates from 2 up to the square root of n. If it finds a divisor, it returns False; otherwise, it returns True.

**Insights on Usage:**  
Always test the generated code and refine your prompt with specific requirements if necessary. The pattern is versatile and can generate code or provide explanations depending on your input.

---

## **Compare and Contrast**

**Summary:**  
The compare_and_contrast pattern examines two subjects or texts and discusses their similarities and differences. It produces an organized analysis that highlights commonalities as well as divergences, typically separating the points into clearly defined sections.

**Best Use Cases:**  
This pattern is ideal for analytical writing and study, such as comparing theories, historical events, products, or any two subjects. It’s useful for generating comparison tables or structured paragraphs for articles, research, or decision-making.

**Example Use [prompt]:**  
For example, to compare two inventors:

~~~bash
fabric -p compare_and_contrast "Tesla vs Edison"
~~~

Alternatively, you could use:

~~~bash
echo -e "Sharks\nDolphins" | fabric -p compare_and_contrast
~~~

**Example Response:**  
For the “Tesla vs Edison” prompt, the output might be:

**Similarities:**  
- Both Nikola Tesla and Thomas Edison were visionary inventors who significantly influenced electrical technology.  
- Each held numerous patents and contributed to the spread of electricity.

**Differences:**  
- Edison was a prolific inventor-businessman known for practical inventions like the light bulb and direct current systems, while Tesla was more theoretical, pioneering alternating current technology.  
- Edison achieved considerable financial success and commercialized his inventions, whereas Tesla’s ideas were often ahead of their time and less commercially exploited.

**Insights on Usage:**  
For a coherent comparison, ensure the two subjects are clearly identified. The pattern structures the response by separating similarities and differences, which is especially useful when comparing items with clear, established points of comparison.

--- 
## **Analyze Interviewer Techniques**

**Summary:**  
This pattern evaluates the questions asked by an interviewer in a conversation or podcast to pinpoint what makes their interviewing technique effective. It acts as an ultra-intelligent analysis tool that “extracts the je ne sais quoi” of great interviewers – in other words, it identifies the special qualities in the interviewer’s questions that set them apart. It scrutinizes every question, analyzing patterns and styles, and then produces a breakdown of the techniques used and a concise summary of why those techniques make the interviewer exceptional.

**Best Use Cases:**  
- When reviewing an interview transcript to learn why a particular interviewer (e.g., a famous journalist or podcast host) is so effective.  
- For aspiring interviewers or podcasters seeking feedback on their own questioning style to improve their technique.  
- Analyzing Q&A sessions or job interviews to extract what the interviewer did to elicit insightful responses.

**Example Use [prompt]:**

~~~bash
$ cat interviewer_transcript.txt | fabric --pattern analyze_interviewer_techniques
~~~

**Example Response:**  
**INTERVIEWER QUESTIONS AND TECHNIQUES:**  
- Q: “How did you overcome your biggest challenge?” – Uses a reflective prompt to encourage a deep, personal story, building empathy and trust.  
- Q: “Why do you think that strategy paid off?” – A probing follow-up that pushes the interviewee to analyze their own reasoning, revealing deeper insights.

**TECHNIQUE ANALYSIS:**  
- **Empathetic Storytelling:** The interviewer asks open-ended questions that invite storytelling, making the conversation intimate and genuine.  
- **Insightful Follow-ups:** They consistently ask “why” to prompt further analysis, uncovering underlying reasons.

**INTERVIEWER TECHNIQUE SUMMARY:**  
This interviewer blends warmth with curiosity, making the guest comfortable enough to share personal stories while consistently probing deeper. The result is an interview full of genuine, insightful answers.

**Insights on Usage:**  
- Provide a full transcript or a complete list of questions for a thorough analysis.  
- Clearly label the roles (interviewer vs. interviewee) to avoid misidentification.  
- Use the output as coaching tips to refine your questioning style.

--- 
## **Analyze Logs**

**Summary:**  
Analyze_logs is designed for IT operations and DevOps, making sense of raw system or application logs. It acts as a seasoned Site Reliability Engineer by reviewing log files to identify unusual patterns, errors, or anomalies, and then summarizing system reliability and performance issues along with suggestions for improvements.

**Best Use Cases:**  
- Diagnosing server issues after an incident by analyzing logs from a specific timeframe.  
- Conducting regular log reviews for maintenance to catch early warning signs such as repeated warnings or performance degradation.  
- Checking the health of a new deployment to spot error patterns or performance issues.

**Example Use [prompt]:**

~~~bash
$ fabric --pattern analyze_logs < /var/log/app/server.log
~~~

**Example Response:**  
**PATTERNS & ANOMALIES:**  
- **Spike in Errors:** Surge of “OutOfMemoryError” entries between 02:00–02:30 UTC, suggesting a memory leak during a nightly batch job.  
- **Frequent Warnings:** Repeated disk space warnings (“Disk at 90% capacity”) each day around 03:00, indicating potential issues with the backup process.

**SYSTEM RELIABILITY INSIGHTS:**  
- The server maintained uptime despite errors, though response times increased during the error spike.  
- Recurring disk space warnings signal a risk of running out of storage.

**RECOMMENDATIONS:**  
- **Fix Memory Leak:** Investigate and patch the suspected module causing the leak.  
- **Increase Disk Capacity/Cleanup:** Expand capacity or adjust backup processes to prevent critical levels.  
- **Monitoring:** Set up alerts for high memory and disk usage.

**Insights on Usage:**  
- Input logs should cover the relevant timeframe due to token limits.  
- Use this analysis as a first-pass diagnostic before deeper investigation.  
- Remove sensitive information from logs before analysis.

--- 
## **Analyze Malware**

**Summary:**  
Analyze_malware provides a cybersecurity-focused analysis of a malware sample, explaining its functionalities, identifying likely attack vectors, and suggesting potential mitigation strategies. It functions like a malware analyst who breaks down what the malware does, how it spreads, and how to defend against it.

**Best Use Cases:**  
- Reverse-engineering assistance for malware by analyzing decompiled code or observed behavior.  
- Generating incident response reports that summarize the malware’s impact and mitigation steps.  
- Enhancing security awareness by explaining malware operations in plain language.

**Example Use [prompt]:**

~~~bash
$ cat suspected_malware.txt | fabric --pattern analyze_malware
~~~

**Example Response:**  
**MALWARE CAPABILITIES:**  
- Records keystrokes and steals passwords via an installed keylogger.  
- Opens a backdoor on port 4444 for remote command execution.  
- Self-propagates through network shares.

**ATTACK VECTORS & BEHAVIOR:**  
- Likely initiated via a malicious email attachment; disguises itself as a legitimate process.  
- Modifies registry keys for persistence and schedules hidden tasks for data exfiltration.  
- Communicates with a command-and-control server (example.evilserver.com).

**POTENTIAL MITIGATIONS:**  
- **Isolation:** Immediately isolate affected machines.  
- **Removal:** Quarantine malicious files and remove altered registry keys; run an updated anti-malware scan.  
- **Patching & User Education:** Patch vulnerabilities and train users on phishing email risks.  
- **Network Defense:** Block outbound traffic to known malicious domains and implement network segmentation.

**Insights on Usage:**  
- Provide detailed logs or decompiled output for a precise analysis.  
- Do not execute actual malware; use safe analysis outputs instead.  
- Validate suggested mitigation steps with official security protocols.

--- 
## **Analyze Military Strategy**

**Summary:**  
This pattern analyzes a military strategy or battle plan by breaking down its objectives, tactics, and overall effectiveness. It highlights strengths and weaknesses, providing a structured critique to assess why the strategy might succeed or fail.

**Best Use Cases:**  
- Historical battle analysis, such as examining Napoleon’s tactics at Waterloo.  
- Fictional scenario planning for military science fiction or wargames.  
- Educational use in military strategy courses for comparative analysis.

**Example Use [prompt]:**

~~~bash
$ fabric --pattern analyze_military_strategy -i battle_plan.txt
~~~

**Example Response:**  
**OBJECTIVES:**  
- Primary: Encircle the enemy’s 5th Division in the valley to cut off supply lines.  
- Secondary: Secure the high ground (Hill 204) for artillery placement.

**STRATEGY & TACTICS:**  
- Pincer movement: Two battalions flank from the north and south at dawn while a frontal feint holds the enemy in place; reserves are poised to exploit breakthroughs.  
- A cavalry unit is assigned to conduct a raid behind enemy lines to disrupt logistics.

**STRENGTHS (Pros):**  
- **Surprise & Shock:** Multi-directional offensive maximizes shock and can quickly collapse enemy defenses.  
- **Terrain Advantage:** Securing Hill 204 provides a commanding view and effective artillery support.  
- **Reserves:** Well-positioned reserves offer flexibility to reinforce breakthroughs.

**WEAKNESSES (Cons):**  
- Extended supply lines for flanking units risk resource depletion.  
- High coordination demands may lead to mis-timed attacks.  
- The center remains thinly defended, exposing vulnerability to counterattacks.

**LIKELY OUTCOME ASSESSMENT:**  
If executed with perfect timing, the enemy could be encircled and forced to capitulate quickly; however, any lapse in coordination could lead to a protracted battle or failure.

**Insights on Usage:**  
- Provide detailed context (force sizes, terrain, timing) for a tailored analysis.  
- Use the analysis for “what-if” scenarios to adjust and refine strategies.  
- Note that real-world factors (morale, weather) should also be considered.

--- 
## **Analyze Mistakes**

**Summary:**  
Analyze_mistakes centers on learning from errors by evaluating a description of an event, project, or process that did not go as planned. It identifies what went wrong, the impact of those mistakes, and provides recommendations on how to avoid similar errors in the future.

**Best Use Cases:**  
- Post-mortem reviews in projects or startups to uncover key mistakes and their impacts.  
- Personal reflection after failures to pinpoint areas for improvement.  
- Sports or game analysis to identify strategic missteps.

**Example Use [prompt]:**

~~~bash
$ fabric --pattern analyze_mistakes -v="#description: Project X fell behind schedule..."
~~~

**Example Response:**  
**IDENTIFIED MISTAKES:**  
- **Unrealistic Timeline:** Allocating only 2 weeks for integration testing led to untested bugs at launch.  
- **Lack of Clear Ownership:** Absence of a dedicated owner for the “User Onboarding” feature caused confusion and duplicate work.  
- **Ignoring Early Red Flags:** Early team warnings were dismissed, missing an opportunity for timely course correction.

**IMPACT OF MISTAKES:**  
- Customers experienced bugs (e.g., payment processing errors) at launch, undermining trust.  
- Poor onboarding resulted in user frustration and high dropout rates.  
- The team experienced burnout and turnover due to a prolonged crunch period.

**LESSONS & RECOMMENDATIONS:**  
- **Improve Planning:** Allocate realistic timelines with built-in buffer periods, especially for testing phases.  
- **Assign Clear Ownership:** Designate a responsible owner for each major feature.  
- **Heed Early Warnings:** Address team concerns promptly with mid-project reviews and adjustments.  
- **Support the Team:** Prevent burnout by enforcing reasonable work hours and potentially hiring additional support.

**Insights on Usage:**  
- Provide a detailed and honest account for precise feedback.  
- Use the output as a checklist for future projects.  
- More detailed inputs yield more specific and actionable recommendations.

--- 
## **Analyze Paper**

**Summary:**  
This pattern acts as a scholarly article assistant that dissects academic papers. It extracts primary findings, summarizes the study’s methodology, lists the authors and their affiliations, and evaluates the paper’s scientific rigor and novelty.

**Best Use Cases:**  
- Literature reviews to quickly grasp the essence of multiple papers.  
- Quality appraisal to assess the credibility and robustness of a study.  
- Drafting abstracts or reports based on detailed paper analyses.  
- Assisting newcomers in translating complex research into accessible summaries.

**Example Use [prompt]:**

~~~bash
$ cat research_paper.txt | fabric --pattern analyze_paper --model gpt-4
~~~

**Example Response:**  
**SUMMARY:**  
A 25-word summary: "The study introduces a new lightweight solar panel design that increases energy capture by ~20% using a novel layered material approach."

**AUTHORS:**  
- Dr. Jane Smith; Dr. Alan Johnson; Dr. Priya Patel

**AUTHOR ORGANIZATIONS:**  
- MIT Media Lab, Massachusetts, USA  
- Department of Materials Science, Stanford University, USA

**FINDINGS:**  
- Developed a layered photovoltaic material that captures both visible and infrared light, increasing conversion efficiency by 20%.  
- Field tests show improved energy generation at dawn/dusk due to infrared capture.  
- Prototype panels demonstrated minimal degradation over 1000 hours.

**STUDY DETAILS:**  
- **Methodology:** Experimental; tested 5 prototypes in lab and outdoor settings.  
- **Comparison:** Benchmarked against leading solar panels under identical conditions.  
- **Data:** Detailed measurements (voltage, current, spectrum analysis) across various wavelengths.

**STUDY QUALITY:**  
- **Design:** Robust controlled study.  
- **Sample Size:** Moderate, sufficient for a prototype demonstration.  
- **Statistical Rigor:** High; results include confidence intervals and p-values (<0.01).  
- **Reproducibility:** Strong; schematics and simulation code provided.

**RESEARCHER’S INTERPRETATION:**  
The multi-layer approach is promising, though long-term durability needs further validation.

**PAPER QUALITY (Ratings):**  
- Novelty: 9/10  
- Rigor: 8/10  
- Empiricism: 9/10

**Insights on Usage:**  
- Provide the full text for best results; if not possible, include key sections.  
- Verify critical details independently.  
- Use the structured output to focus on essential aspects of the study.

--- 
## **Analyze Patent**

**Summary:**  
Analyze_patent functions as a virtual patent examiner. It evaluates a patent application by identifying the invention’s field, the problem addressed, the proposed solution, and its advantages. It also assesses novelty and inventive step, then provides a detailed summary along with up to 20 keywords capturing the core idea.

**Best Use Cases:**  
- For inventors to receive objective feedback on their patent drafts or to analyze competitor patents.  
- Prior art review by summarizing multiple patents for comparison.  
- Educational use in patent law courses.  
- Translating dense patent language into a more accessible summary.

**Example Use [prompt]:**

~~~bash
$ fabric --pattern analyze_patent -i patent_application.txt
~~~

**Example Response:**  
**FIELD OF THE INVENTION:**  
Solar energy technology, specifically improvements in photovoltaic panel design for enhanced energy efficiency.

**PROBLEM ADDRESSED:**  
Inefficiencies in current solar panels due to wasted infrared heat.

**SOLUTION (INVENTION):**  
A dual-layer solar panel system that integrates a conventional photovoltaic cell with a thermoelectric layer to convert waste heat into electricity.

**ADVANTAGES:**  
- Increases energy output by approximately 20%.  
- Maintains a similar panel footprint.  
- Enhances thermal management and prolongs cell lifespan.

**NOVELTY & INVENTIVE STEP:**  
Combines two energy conversion mechanisms in a compact design using a new transparent thermoelectric polymer, which is not found in prior art.

**PATENT SUMMARY:**  
A two-layer solar panel that generates electricity from both sunlight and heat, significantly boosting efficiency.

**KEYWORDS:**  
solar panel; dual-layer; photovoltaic; thermoelectric; waste heat; improved efficiency; integrated energy harvesting; hybrid solar system; thermal conversion; spectrum utilization

**Insights on Usage:**  
- Ensure the input includes claims and structured sections for detailed analysis.  
- Use the generated keywords for further research.  
- Treat the novelty assessment as a preliminary evaluation; conduct formal prior art searches as needed.

--- 
## **Analyze Personality**

**Summary:**  
Analyze_personality examines a body of text (e.g., emails, speeches, or written content) to infer the personality and communication style of the author. It considers word choice, tone, formality, and emotional cues to produce a profile of key personality traits.

**Best Use Cases:**  
- Reviewing professional communication to understand how your tone is perceived.  
- Character analysis for creative writing.  
- Analyzing social media posts or public figures’ writings.  
- Personal self-improvement by identifying tendencies such as aggressiveness or passivity.

**Example Use [prompt]:**

~~~bash
$ cat sample_emails.txt | fabric --pattern analyze_personality
~~~

**Example Response:**  
**COMMUNICATION STYLE:**  
The writer uses a polite, formal tone with well-structured sentences and proper grammar, indicating conscientiousness.

**EMOTIONAL TONE:**  
Calm and positive, with frequent expressions of gratitude, suggesting emotional stability and warmth.

**SOCIAL ORIENTATION:**  
Focuses on tasks and ideas with limited personal storytelling, hinting at an introverted, analytical nature while still showing empathy.

**THINKING STYLE:**  
Detail-oriented and organized, often employing bullet points and structured lists, reflecting a logical and methodical approach.

**KEY PERSONALITY TRAITS (inferred):**  
- Conscientiousness: High  
- Agreeableness: High  
- Emotional Stability: High  
- Extroversion: Moderate to Low  
- Openness: Moderate

**Insights on Usage:**  
- Use a large, varied text sample for a more reliable profile.  
- Consider context when interpreting the results (formal work emails vs. casual messages).  
- Treat the analysis as indicative rather than a definitive psychological assessment.

--- 
## **Analyze Presentation**

**Summary:**  
Analyze_presentation provides feedback on the content of a presentation or speech. It critiques structure, clarity, engagement, and overall effectiveness, acting as a public speaking coach to help refine your script or slide text.

**Best Use Cases:**  
- Preparing a speech or pitch by identifying issues in transitions, clarity, and tone.  
- Post-presentation analysis to gather feedback for improvement.  
- Training sessions for public speaking.  
- Reviewing slide content to ensure it supports the narrative effectively.

**Example Use [prompt]:**

~~~bash
$ fabric --pattern analyze_presentation < keynote_draft.txt
~~~

**Example Response:**  
**STRUCTURE & FLOW:**  
The presentation has a clear introduction and conclusion; however, transitions between sections are abrupt. Consider adding bridging sentences between segments.

**CLARITY OF MESSAGE:**  
The core message is present but could be stated more explicitly at the outset. Simplify jargon to ensure all audience members understand.

**ENGAGEMENT & TONE:**  
A personal anecdote at the start is engaging, but the tone becomes overly formal in the middle. Maintain a consistent, conversational tone throughout.

**STRENGTHS:**  
- **Credibility:** Citing relevant studies enhances authority.  
- **Conclusion:** The wrap-up ties back to the opening anecdote effectively.  
- **Visual Potential:** Vivid language can be paired with strong visuals.

**AREAS FOR IMPROVEMENT:**  
- Improve pacing by inserting pauses or rhetorical questions after dense information.  
- Increase audience interaction with direct questions or prompts.  
- Emphasize key takeaways more clearly.

**Insights on Usage:**  
- Include stage directions or notes for context (e.g., “[pause for effect]”).  
- Provide a full draft (introduction through conclusion) for comprehensive feedback.  
- Use the feedback to iteratively refine your presentation.

--- 
## **Analyze Product Feedback**

**Summary:**  
Analyze_product_feedback processes a collection of product feedback (customer reviews, survey responses, etc.) to generate a qualitative analysis of user sentiments. It summarizes common positive sentiments, negative complaints, and frequently requested improvements, offering an overall view of customer satisfaction.

**Best Use Cases:**  
- Triage large volumes of survey responses to identify major themes.  
- Review post-release feedback to assess the impact of new features.  
- Conduct periodic product health checks to monitor emerging issues.  
- Perform comparative analysis between competing products.

**Example Use [prompt]:**

~~~bash
$ cat user_feedback.csv | fabric --pattern analyze_product_feedback
~~~

**Example Response:**  
**POSITIVE FEEDBACK THEMES:**  
- **User-Friendly Interface:** Users praise the app’s intuitive design.  
- **Feature X Success:** The new offline mode is highly appreciated, especially during poor network conditions.  
- **Customer Support:** Quick and helpful responses from support are frequently mentioned.

**NEGATIVE FEEDBACK THEMES:**  
- **Performance Issues:** Many users report lag and crashes, particularly on older devices.  
- **Battery Drain:** Significant battery consumption is a common complaint.  
- **Feature Y Removal:** Long-time users express dissatisfaction over the removal of a previously popular feature.

**TOP REQUESTED IMPROVEMENTS:**  
- Introduction of Dark Mode to reduce eye strain.  
- More customization options for personalizing the interface.  
- Additional integrations with external services (e.g., Google Fit, Slack).

**OVERALL SENTIMENT:**  
The feedback is mixed, leaning towards positive overall, though technical issues remain a significant concern.

**Insights on Usage:**  
- Pre-process feedback to deduplicate repetitive entries for nuanced analysis.  
- Use the detailed breakdown to guide product improvement priorities.  
- For very large datasets, consider chunking feedback and then aggregating summaries.
