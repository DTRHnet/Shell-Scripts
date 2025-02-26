
## agility_story

**Summary**: Generates an Agile user story (often with acceptance criteria) from a given topic or requirement ￼. This pattern helps turn a brief feature description into a structured user story for Agile development (e.g., “As a [role], I want [feature] so that [benefit]”).
**[prompt]**: echo "Build a user login feature for the website" | fabric --pattern agility_story
**Response**:
{
  "User Story": "As a website user, I want to log into the site so that I can access personalized features.",
  "Acceptance Criteria": [
    "Users can enter a username and password to log in",
    "Successful login grants access to user-specific content",
    "Invalid login attempts show an error message without revealing which part is incorrect"
  ]
}


## ai

Summary: Produces a short explanation of a given AI concept or technology ￼. In other words, it acts as a quick AI encyclopedia: you provide the name of an AI-related topic, and it returns a concise, plain-language description.
Example Use [prompt]: echo "Neural networks" | fabric --pattern ai
Example Response:
**Neural Networks:** Neural networks are a type of machine learning model inspired by the human brain. They consist of layers of interconnected "neurons" that process data. These networks learn patterns from large amounts of examples. For instance, a neural network can learn to recognize images of cats by adjusting the connections (weights) between neurons during a training process. Over time, it becomes very good at mapping inputs (like an image) to the correct output (identifying the image as a cat) without being explicitly programmed with rules.


## analyze_answers

Summary: Examines a set of answers (e.g. responses to a question) to evaluate their accuracy, relevance, and any potential biases ￼. This pattern is useful for checking multiple answers – for instance, answers from different people or AI – and judging which are correct or if they contain errors or bias.
Example Use [prompt]: echo $'Q: What is the capital of France?\nAnswer 1: London\nAnswer 2: Paris\nAnswer 3: Paris, but I think it\'s in Italy.' | fabric --pattern analyze_answers
Example Response:
**Analysis of Answers:**
- **Answer 1 (London):** Incorrect. London is the capital of the UK, not France. *Accuracy:* Low (the answer is wrong). *Relevance:* The answer addresses the question but is factually wrong. *Bias:* No obvious bias, just a factual error.
- **Answer 2 (Paris):** Correct. Paris is the capital of France. *Accuracy:* High. *Relevance:* Directly answers the question. *Bias:* None – this is a straightforward factual answer.
- **Answer 3 (“Paris, but I think it’s in Italy”):** Partially correct. It correctly identifies Paris as the capital of France, but then shows confusion about the country. *Accuracy:* Medium (mixed correctness). *Relevance:* Mentions the right city but adds irrelevant/incorrect info. *Bias:* Indicates a possible knowledge gap (mistaking France vs. Italy) rather than bias.


## analyze_candidates

Summary: Evaluates information about multiple candidates (such as job applicants) to compare their qualifications and fit for a role. This pattern analyzes each candidate’s strengths and weaknesses based on the provided input ￼. In a hiring scenario, for example, it would help highlight which candidate better meets the requirements or where each excels.
Example Use [prompt]: echo "Candidate A: 5 years experience in software development (Java, Python). Candidate B: 3 years experience (Python), background in data science." | fabric --pattern analyze_candidates
Example Response:
**Candidate A:** Has 5 years of software development experience, which suggests a strong foundation in building applications. Proficient in Java and Python – this breadth in languages indicates versatility. Likely capable of leading development tasks and mentoring, given the longer experience. *Strengths:* Extensive experience, expertise in full-stack development. *Weaknesses:* Less data science experience.
**Candidate B:** Has 3 years of experience, focused on Python and data science. This candidate may bring valuable machine learning and data analysis skills. *Strengths:* Modern data science background, likely strong in analytics and ML. *Weaknesses:* Overall development experience is shorter, which might mean less exposure to large-scale software projects.
**Comparison:** For a pure software development role, Candidate A’s longer experience might be advantageous for immediate productivity. For a role that involves data-driven features or machine learning, Candidate B offers relevant expertise. **Fit Recommendation:** If the position is a general software engineer for building application features, Candidate A is a stronger fit. If the role requires implementing data science or analytics, Candidate B’s skillset could be more valuable.


## analyze_cfp_submission

Summary: Reviews a “Call for Proposals” submission (such as a conference talk proposal or research abstract). The pattern analyzes the submission’s content for clarity, relevance to the CFP topic, strengths, and weaknesses, offering feedback on how well it meets the criteria and how it could be improved. (CFP = Call for Proposals, often for conference talks or papers.)
Example Use [prompt]: echo $'Title: AI in Healthcare\nAbstract: This talk will explore how artificial intelligence can improve patient outcomes, including examples of machine learning in medical diagnosis and personalized treatment.' | fabric --pattern analyze_cfp_submission
Example Response:
**Proposal Title:** “AI in Healthcare”
**Summary of Proposal:** The submission intends to discuss applications of artificial intelligence to improve patient outcomes. It mentions using machine learning for medical diagnosis and personalized treatment, indicating real-world examples will be provided.
**Strengths:** The topic is timely and highly relevant to the healthcare industry. The proposal promises practical examples (“machine learning in medical diagnosis and personalized treatment”), which adds credibility. The focus on patient outcomes gives a clear value proposition for the audience.
**Weaknesses/Areas for Improvement:** The abstract is somewhat broad. It could be more specific about which aspects of AI (e.g., specific algorithms or case studies) will be covered. Also, it doesn’t mention any results or conclusions – adding expected takeaways or findings could strengthen the proposal. Ensuring the talk has a clear narrative (problem -> AI solution -> outcome) would help.
**Relevance to CFP:** High. It squarely addresses AI in a real-world domain (healthcare) and should attract interest due to the subject’s importance.
**Overall Feedback:** A strong proposal idea. To improve it further, the author should add more detail on the content structure and emphasize any unique insights or results the talk will provide. This will make it more compelling to the reviewers and audience.


## analyze_claims

Summary: Dissects the truth claims in a piece of text and provides a balanced analysis ￼. This pattern will summarize the overall argument, then for each claim it finds: list the claim, give evidence supporting it, evidence refuting it, point out any logical fallacies, and even assign a truthfulness rating. It’s meant to critically analyze assertions in the input content for veracity and bias.
Example Use [prompt]: echo "According to some sources, the global climate is not warming; in fact, certain scientists have proven that the Earth is cooling." | fabric --pattern analyze_claims
Example Response:
**ARGUMENT SUMMARY:** The input claims that global climate change is not happening and instead argues the Earth is cooling, citing “certain scientists” as evidence.
**TRUTH CLAIMS:**
- **CLAIM:** *“The global climate is not warming; the Earth is actually cooling.”*  
- **CLAIM SUPPORT EVIDENCE:** Proponents of this claim sometimes point to short-term cooling periods (e.g. a few years in the mid-20th century) or cherry-picked regional data as evidence. For instance, they might note that between 1940 and 1970, average temperatures in the Northern Hemisphere slightly dropped.  
- **CLAIM REFUTATION EVIDENCE:** Extensive, long-term global data show a clear warming trend. NASA and NOAA data indicate that the last decade was the warmest on record globally, and the overall global average temperature has increased by about 1°C since the late 19th century. This broad scientific consensus directly contradicts the claim of overall cooling.  
- **LOGICAL FALLACIES:** The claim employs **cherry-picking** (focusing on an unusual short-term cooling period while ignoring the long-term warming trend). It also uses an **appeal to vague authority** (“certain scientists”) without credible citations.  
- **CLAIM RATING:** **F (Definitely False).** The overwhelming majority of evidence shows the climate is warming, not cooling.
**ADDITIONAL NOTES:** The argument is misleading, as it takes a complex topic like climate trends and presents a false conclusion by omitting context. A balanced view of climate data strongly supports warming.


## analyze_comments

Summary: Analyzes a collection of user comments to extract insights about sentiment, common themes, and potential issues. This pattern digests comments (for example, feedback on a product or post) and outputs an overview such as overall sentiment (positive/negative/mixed), recurring points of praise or criticism, and any notable biases or concerns expressed by commenters.
Example Use [prompt]: echo $'Comment 1: I love the new interface, it\\'s very user-friendly and intuitive.\nComment 2: The app keeps crashing and customer support is unhelpful.' | fabric --pattern analyze_comments
Example Response:
**Overall Sentiment:** Mixed – one commenter is very positive about the product interface, while another is clearly frustrated with the app’s stability and support.
**Key Themes Identified:**  
- *Positive Feedback:* The **user interface design** is praised for being user-friendly and intuitive. This suggests the recent changes to the UI are successful and well-received by at least some users.  
- *Negative Feedback:* **App stability/reliability** is a problem (reports of frequent crashes). Additionally, **customer support** is criticized as unhelpful. These are areas of concern that might need immediate attention.
**Comment-Specific Notes:**  
- Comment 1 is enthusiastic about usability, indicating that ease of use is a strong selling point of the app.  
- Comment 2 points out a serious issue (crashing) and dissatisfaction with support, indicating a gap in user experience post-release.
**Potential Biases:** Neither comment shows obvious bias; they appear to be genuine user experiences (one positive, one negative). The second comment is strongly negative, but it’s focused on specific issues rather than derogatory language.
**Suggestions:** Focus on stability improvements and customer support training. The positive feedback on interface can be used in marketing, but the crashing issue must be addressed to prevent losing user trust.

## analyze_debate

Summary: Provides an in-depth analysis of a debate transcript ￼. This pattern evaluates how insightful and emotionally charged the debate is, identifies participants and analyzes their arguments, and outlines points of agreement or disagreement. The output includes an insightfulness score and emotionality score for the debate, a breakdown of each participant’s stance, evidence backing or refuting key arguments, and highlights of any agreements, unresolved disagreements, misunderstandings, as well as lessons or takeaways from the debate ￼. It essentially helps the user understand the debate’s content and quality at a glance.
Example Use [prompt]: echo $'Debater A: We should invest in renewable energy to combat climate change.\nDebater B: Renewable energy is too expensive and not reliable enough.' | fabric --pattern analyze_debate
Example Response:
**INSIGHTFULNESS SCORE (0-10):** 5  
*The debate offers some substantive points but remains surface-level. There is an exchange of viewpoints, but neither side provides in-depth evidence.*  
**EMOTIONALITY SCORE (0-5):** 1  
*Both participants keep a mostly calm tone with no obvious anger or excessive emotion.*  
**PARTICIPANTS:**  
- **Debater A (Emotionality: 1):** Advocates for investing in renewable energy as a necessity to combat climate change. A’s approach is calm and focused on long-term benefits and environmental responsibility.  
- **Debater B (Emotionality: 1):** Argues against renewables by citing cost and reliability concerns. B remains composed while emphasizing economic practicality and current technological limits.
**ARGUMENTS:**  
- **Debater A’s Arguments:** Renewable energy is essential to fight climate change. A implies that not investing now would be irresponsible for future generations. *Evidence/Support:* References the urgency of climate reports and falling costs of renewables (though not explicitly cited in the snippet).  
- **Debater B’s Arguments:** Renewable technologies are too costly and intermittent to replace traditional energy fully. *Evidence/Support:* Points to high initial investments and instances where solar/wind production is low (again not detailed in the snippet). *Counterpoint:* B does not address A’s climate urgency argument, focusing only on economic factors.
**AGREEMENTS:**  
None explicitly stated. Both participants seem to agree that energy decisions involve trade-offs, but they do not openly acknowledge any common ground in this excerpt.
**DISAGREEMENTS:**  
They fundamentally disagree on priority: A prioritizes environmental impact and long-term gains of renewables, while B prioritizes short-term cost and reliability issues. There is a clear clash between *environmental necessity* vs. *economic feasibility*.
**POSSIBLE MISUNDERSTANDINGS:**  
Debater A might assume all cost concerns are short-sighted without addressing them, while Debater B might be operating under outdated information about renewable costs or ignoring long-term cost savings. Each may slightly misunderstand the weight the other gives to their concerns.
**LEARNINGS:**  
The debate highlights the classic tension in energy policy between sustainability and cost. It shows that factual data (cost trends, reliability improvements) would benefit the discussion. It also suggests that values (future sustainability vs. present economics) drive each side’s stance.
**TAKEAWAYS:**  
For a more productive debate, both sides could incorporate each other’s points: A could address cost/reliability with data on improvements in renewable tech, and B could acknowledge the environmental stakes. This would move the discussion toward a more informed middle ground.


## analyze_email_headers

Summary: Inspects raw email header data to trace an email’s origin and identify any anomalies or signs of spoofing. This pattern parses through header lines (such as “Received” chains, SPF/DKIM authentication results, sender/recipient info) and provides an analysis of whether the email is legitimate or suspicious. It can help uncover misconfigurations or malicious indicators in an email’s metadata.
Example Use [prompt]: echo $'Received: from mail.example.com (192.168.1.100) by mx.google.com;\nSPF: PASS;\nDKIM: PASS;\nFrom: \"Trusted Sender\" <noreply@example.com>;\nReply-To: attacker@malicious.com' | fabric --pattern analyze_email_headers
Example Response:
**Email Header Analysis:**
- **Originating Server:** The email was received from `mail.example.com` with IP `192.168.1.100`. This appears to be the legitimate mail server for **example.com** (internal IP used for example). The chain shows it passed through Google’s mail exchange (mx.google.com), indicating it was sent to a Gmail address.
- **Authentication Results:** SPF check is **PASS**, meaning the sending server was authorized to send on behalf of example.com. DKIM is **PASS**, so the message content was likely not tampered with in transit and the signature matches the example.com domain. These results suggest the email *technically* passed authentication for the example.com domain.
- **Sender vs Reply-To:** The `From` address is `noreply@example.com` (which matches the domain that passed SPF/DKIM). However, the `Reply-To` is set to `attacker@malicious.com`, which is a **red flag**. This mismatch implies that while the email came from a legitimate server, it is trying to funnel replies to a different domain. This is a common tactic in phishing emails – the message is sent from a real domain (to pass SPF/DKIM checks) but any responses would go to the attacker’s address.
- **Analysis Summary:** The headers indicate the email *originated from the legitimate example.com server and passed authentication*, but the presence of a Reply-To pointing to another domain is suspicious. This likely means the sender’s account or server was compromised to send phishing emails. **Verdict:** The email is potentially malicious (phishing attempt) despite passing SPF/DKIM, due to the deceptive Reply-To address.
- **Recommendation:** Do not trust emails with such header discrepancies. Investigate the example.com sender account for compromise. The recipient should be cautious and not click links or reply to the malicious address.


## analyze_incident

Summary: Analyzes an incident report (for example, a cybersecurity breach or IT outage report) to extract key details and provide an assessment. This pattern will summarize what happened, identify the root cause of the incident, describe the impact, evaluate the response, and often suggest preventive measures for the future. It’s meant to turn a raw incident description into a clear post-mortem style analysis.
Example Use [prompt]: echo "Incident: On Jan 1, attackers exploited an XSS vulnerability on our site, stealing user data. The team identified the issue and patched it within 24 hours." | fabric --pattern analyze_incident
Example Response:
**Incident Summary:** On January 1st, an attacker exploited a cross-site scripting (XSS) vulnerability on the website, which allowed them to steal user data. The security team discovered the breach and applied a patch to fix the vulnerability within 24 hours.
**Impact:** User data was compromised during the attack. The stolen data could include sensitive user information (e.g. usernames, maybe emails or session tokens, depending on what the XSS exposed). This incident likely affected all users who loaded the infected page while the attack was active. Customer trust and safety are at risk, and there may be legal/compliance implications if personal data was taken.
**Root Cause:** The root cause was an unpatched XSS flaw in the web application. This indicates insufficient input sanitization on user-provided data (allowing malicious scripts to run). It also suggests that prior security testing did not catch this vulnerability.
**Response Evaluation:** The team reacted quickly – the issue was identified and patched within a day, which is a positive outcome. Containing the breach in 24 hours limited the window of exposure. The team likely also alerted users and invalidated sessions or took other steps to secure accounts, though that’s not stated here.
**Recommendations:**  
- **Improve Input Validation:** Ensure all user inputs are properly sanitized or encoded to prevent XSS. Conduct a thorough security code review and apply stricter validation frameworks.  
- **Security Testing:** Implement regular security testing (penetration testing or automated scans) to catch vulnerabilities like XSS before deployment.  
- **Monitoring and Incident Response:** Enhance monitoring to detect such attacks in real-time. The quick response was good, but earlier detection (e.g., via anomaly detection or error logs) could further minimize damage.  
- **User Notification:** If not done already, inform affected users about the breach and advise them on any necessary actions (like changing passwords if credentials might be impacted). Also consider providing guidance on how you will prevent such issues going forward to rebuild trust.
**Conclusion:** This incident underscores the importance of web application security best practices. While the response was swift and the flaw is now patched, the company should take proactive steps to prevent similar vulnerabilities and prepare for future incidents.


