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