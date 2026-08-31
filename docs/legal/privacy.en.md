# PRIVACY NOTICE

**Controller:** Vicente Nevarez Treviño
**Application:** Agora
**Version:** 1.0 · **Issued:** `[DATE]` · **Last updated:** `[DATE]`

> The Spanish version ([privacy.es.md](privacy.es.md)) is the governing text. This translation is provided solely to facilitate comprehension.

---

## 1. Identity and address of the Controller

1.1. Vicente Nevarez Treviño, with address at `[STREET, NUMBER, DISTRICT, POSTAL CODE, CITY, STATE]`, United Mexican States (hereinafter, the **Controller**), is responsible for the processing of personal data collected through the Agora application and the site `https://agora.mobi`.

1.2. Email address designated for privacy matters and the exercise of rights: `privacidad@agora.mobi`.

1.3. This Privacy Notice is issued in compliance with the **Federal Law on the Protection of Personal Data Held by Private Parties**, published in the Official Gazette of the Federation on 20 March 2025 and in force as of 21 March 2025 (hereinafter, the **Law**), and with any regulations derived therefrom.

1.4. Use of the Application is additionally governed by the [Terms and Conditions of Use](terms.en.md), which form an integral part of the relationship between the Controller and the User.

## 2. Definitions

For the purposes of this Privacy Notice, the following terms shall have the meanings set out below:

**Application:** the software known as Agora, in any of its versions for the macOS, Windows, Android and iOS operating systems, as well as its browser-executable version.

**Local mode:** the operating modality in which no account is created and all information remains stored on the User's device.

**Cloud mode:** the operating modality in which the User creates an account and enables synchronisation of content with the Controller's infrastructure.

**Participant:** the natural person whose data is entered by the User into the Application's directory for the purpose of assigning them parts of the meeting program.

**Data Subject:** the natural person to whom the personal data pertains.

**User:** the natural person who installs and uses the Application.

## 3. Scope and operating modalities

3.1. The Application operates under two modalities whose personal data processing regimes are substantially different. The applicable regime depends on the modality chosen by the User.

| Item | Local mode | Cloud mode |
|---|---|---|
| Location of information | Exclusively on the User's device | On the User's device and on Google (Firebase) infrastructure |
| Capacity of the Controller | None with respect to content: it neither processes it nor has access to it | Processor with respect to congregation content; Controller with respect to account data and telemetry |
| Encryption of the local database | Encrypted with AES (SQLite3MultipleCiphers), key wrapped by the User's password | Identical in installed versions; without additional encryption in the browser version (section 15) |
| Network communications | Solely the download of publications referred to in section 11 | The foregoing, plus synchronisation of encrypted content |
| Access to content | Solely a person holding both the device and the password | The User, the members the User authorises and, on the terms of section 8, the Controller |
| Effect of uninstallation | Deletion of the information, with no copy remaining in the Controller's possession | The cloud-hosted copy subsists until deleted pursuant to section 13 |

3.2. Local mode is the Application's default modality and is not limited in functionality relative to cloud mode, save as regards synchronisation across devices and collaboration among multiple users.

## 4. Categories of personal data processed

### 4.1. Personal data of the User

| Category | Collection event | Location |
|---|---|---|
| Email address | Creation of a cloud account | Firebase Authentication |
| Name and profile image | Authentication through the Google provider | Firebase Authentication |
| User identifier (UID) and random device identifier | Account creation and synchronisation | Firebase |
| Local password | Configuration of local access | Not stored. Used solely to derive the key that wraps the database encryption key |
| Interface language, theme and preferences | Use of the Application | Exclusively on the device |
| Diagnostic and usage data | Solely upon prior consent, pursuant to section 12 | Google Firebase |

### 4.2. Personal data of third parties entered by the User

The User enters into the Application personal data of Participants, most of whom are not users of the Application. Such data comprises:

a) First name, surname and the display name used in the printed document;
b) Gender;
c) Congregation privilege: elder, ministerial servant or publisher;
d) Qualifications determining the parts to which the Participant may be assigned;
e) Periods of absence, with dates and a free-text comment;
f) Free-text notes;
g) Assignments by name, per week and per part of the program;
h) Congregation details: name, number, circuit, circuit overseer's name and meeting schedule.

### 4.3. Information not constituting personal data

The Application retains a local copy of the reference publications downloaded pursuant to section 11. That copy constitutes public reference content, contains no personal data and is not synchronised.

## 5. Sensitive personal data and the User's capacity as controller

5.1. **Sensitive nature of the data.** Pursuant to Article 8 of the Law, data revealing religious beliefs is deemed sensitive personal data. Recording the congregation privilege referred to in subsection (c) of section 4.2 reveals the Participant's religious belief and therefore constitutes sensitive personal data.

5.2. **Applicable consent regime.** Processing of sensitive personal data requires the express, written consent of the Data Subject, granted by handwritten signature, electronic signature or any equivalent authentication mechanism.

5.3. **Determination of the controller.** With respect to Participants' personal data, the controller of the processing is the User, who determines what data is collected, in respect of which persons and for what purpose. The Controller supplies solely the technical means. In local mode, the Controller has no material access to such information.

5.4. **Representations of the User.** By using the Application, the User represents that:

a) It holds a legitimate basis for processing the personal data of the Participants it enters;
b) It has obtained consent on the terms required by applicable legislation, including express written consent in respect of sensitive data;
c) It will make available to Participants the information relating to the processing and will attend to the exercise of their rights;
d) It will observe the principle of proportionality, limiting processing to the data necessary for the preparation of the meeting program.

5.5. **Free-text fields.** The fields designated *notes* and *absence comment* accept text without content restriction. The Controller expressly recommends refraining from entering therein information relating to health status, family circumstances or any other personal condition, given that such information would be subject to the same processing and storage regime as the remaining content, thereby increasing the impact of any security breach.

## 6. Purposes of processing

6.1. **Primary purposes.** These are necessary for the existence and performance of the relationship between the Controller and the User:

a) Generating, editing and exporting meeting programs in PDF format;
b) Computing schedules, durations and assignment eligibility rules;
c) Preserving the User's work between sessions on the device;
d) Downloading and locally storing reference publications;
e) In cloud mode: authenticating the User, synchronising information across their devices and enabling collaboration with the members they authorise;
f) Handling support requests and requests for the exercise of rights.

6.2. **Secondary purposes.** These are not necessary for the relationship and their refusal does not condition access to any functionality:

g) Measuring the stability of the Application and diagnosing faults;
h) Understanding, in aggregate, the use of functionalities, for product development purposes.

6.3. Processing for the purposes set out in subsections (g) and (h) requires the User's prior consent and may be withdrawn at any time pursuant to section 19.

6.4. **Express limitations on processing.** The Controller does not sell, lease or assign personal data to third parties; does not process data for advertising or marketing purposes; does not build profiles of Data Subjects; does not submit congregation content to the training of artificial intelligence systems; and does not access content for any purpose other than the operation of the service.

## 7. Consent

7.1. Processing for the primary purposes is grounded in the necessity of performing the legal relationship between the Controller and the User.

7.2. Processing for the secondary purposes is grounded in the User's express consent, obtained prior to the commencement of such processing.

7.3. Installation and use of the Application in local mode does not entail any processing of personal data by the Controller.

## 8. Encryption of synchronised content and the scope of its protection

8.1. Content synchronised by the User in cloud mode is encrypted on their device using the **AES-256-GCM** algorithm, under a cryptographic key specific to each congregation, prior to transmission. The infrastructure stores opaque encrypted blocks and routing metadata consisting of identifiers, timestamps and membership relationships.

8.2. The private key that grants access to those cryptographic keys is **escrowed in the User's account within the infrastructure**. This design decision serves the purpose of enabling the User to recover their information in full upon signing in from a different device, without needing to safeguard a recovery phrase.

8.3. **Express declaration.** So that the User may reach an informed decision, the Controller declares that, as a direct consequence of the matter set out in section 8.2, whoever controls the cloud infrastructure project possesses the **technical capability to decrypt the content of any congregation**.

8.4. **Scope of the protection.** The encryption described produces the following effects:

a) It prevents a revoked member from accessing content generated after the revocation;
b) It prevents the content from being read in the event of unauthorised access to the database;
c) It prevents access to the content by the infrastructure provider.

It does not, by contrast, produce the following effects:

d) It does not prevent access to the content by the Controller;
e) It does not prevent compliance with an order issued by a competent authority and directed to the Controller.

8.5. **Undertaking of the Controller.** For as long as the described scheme subsists, the Controller undertakes not to access the content of any congregation, save in the following cases: (i) the User's express request for the resolution of a technical incident; or (ii) a written, duly founded and reasoned order of a competent authority. In the second case, the Controller will notify the User unless prohibited by law from doing so.

8.6. **Available alternative.** A User who does not consider the described scheme acceptable may operate the Application in local mode, in which case the Controller has no access to the information.

8.7. **Future modifications.** Removal of key escrow is technically feasible and under evaluation. Its implementation would have the consequence that loss of the password would likewise entail loss of the cloud-hosted copy; accordingly, should it be adopted, it will be submitted to the User's decision and will not be applied automatically. This Notice describes the scheme in force as at the date of its issue.

## 9. Transmissions to processors

9.1. The Controller makes no transfers of personal data to third parties for those third parties' own purposes.

9.2. The Controller relies on the following processors, which process personal data on its behalf and under its instruction:

| Processor | Purpose | Data communicated | Location |
|---|---|---|---|
| Google (Firebase Authentication) | Account authentication | Email address, UID and, where applicable, name and profile image | `[REGION — confirm in console]` |
| Google (Cloud Firestore) | Synchronisation across devices | Encrypted blocks and routing metadata | `[REGION]` |
| Google (Crashlytics and Analytics) | Fault diagnosis and aggregate usage measurement | Upon prior consent: device model, operating system version, approximate country and error traces | United States of America |
| Google (Firebase Hosting and App Check) | Hosting of the site and verification of request authenticity | IP address, user agent and access logs | Global |
| `[SMTP PROVIDER]` | Delivery of password reset and verification email | Email address | `[REGION]` |

9.3. The Controller will disclose personal data to a competent authority solely by virtue of a duly founded and reasoned demand, and exclusively to the extent required.

## 10. International transfers

10.1. Operation in cloud mode entails that personal data be stored and processed outside the territory of the United Mexican States, principally in the United States of America.

10.2. Use of cloud mode constitutes the User's consent to such transfer. Operation in local mode entails no international transfer.

## 11. Connection with third-party servers

11.1. When the Application requires a publication not held in its local copy, it issues a request to the server `app.jw-cdn.org`. That request is made under both operating modalities, including in the absence of an account.

11.2. In that communication, the destination server receives the device's IP address, the time of the request and the language of the publication requested. The Controller does not intervene in that communication, has no knowledge of it and does not log it.

11.3. The server referred to belongs to a third party that observes its own processing practices, over which the Controller has no control. No data relating to the User's congregation is communicated to that server.

## 12. Diagnostic and analytics data

12.1. On first launch of the Application, the User's consent is requested for the transmission of diagnostic and usage data. Until such consent is granted, no transmission takes place. Refusal does not alter the functionality of the Application.

12.2. Where consent is granted, the processing comprises:

a) **Fault diagnosis (Crashlytics):** error traces, Application version, device model and operating system version. It does not comprise names of persons, program content or the congregation database.

b) **Usage analytics (Analytics):** aggregate session events, approximate country derived from the IP address, and device type. It does not comprise identification by name or processing for advertising purposes.

12.3. Consent may be withdrawn at any time from the Application's settings section, taking effect immediately.

## 13. Retention periods and deletion

| Category | Retention period | Means of deletion |
|---|---|---|
| Local database | For as long as the installation subsists | Deletion from within the Application or uninstallation |
| Synchronised content | For as long as the cloud congregation subsists | Deletion of cloud data by the administrator, or deletion of the account |
| Account data | For as long as the account subsists | Account deletion from within the Application |
| Deletion records (sync tombstones) | 90 days | Automatic purge |
| Pending invitations | Until expiry or cancellation | Automatic, or by act of the administrator |
| Diagnostics and analytics | Up to 90 days (diagnostics) and up to 14 months (analytics), per the processor's retention | Withdrawal of consent interrupts transmission; information previously transmitted completes its retention cycle |
| Hosting access logs | The processor's standard retention | Automatic purge |
| Support correspondence | 24 months | Upon the User's request |

13.1. Deletion of the account comprises the deletion of the User's identity, of their cryptographic keys and of the congregations they administer.

13.2. Deletion of the account does not comprise the deletion of the local database held on the User's devices, which remains under their control and continues to operate in local mode. Its deletion is effected from within the Application or by uninstallation.

13.3. The User may request deletion of their account and associated data by web, without needing to reinstall the Application, at `https://agora.mobi/cuenta/eliminar`.

## 14. Irrecoverability of the local password

14.1. The key encrypting the local database is wrapped by the User's password. The Controller stores neither the password nor any copy of that key, and there exists no recovery mechanism, security question, rescue email or alternative access.

14.2. Consequently, **forgetting the local password results in the definitive and irreversible loss of the information contained on the corresponding device**, including as regards the Controller.

14.3. That characteristic is a direct consequence of the encryption scheme adopted, the purpose of which is to prevent access by any third party to the local database. It falls to the User to export periodic backups in `.jwpp` format and to safeguard them. Such file is encrypted with the password the User determines at the time of export, which is likewise not susceptible of recovery.

## 15. Storage in the browser version

15.1. In the version of the Application executed in a web browser, the local database is stored in browser storage **without additional encryption**.

15.2. The technical basis for the foregoing is that the encryption component used in the installed versions has no implementation for that environment, and that in the browser the effective boundary is provided by the same-origin policy: a party able to access the origin's storage would likewise be able to access the key.

15.3. As a consequence, in the browser version a code-injection vulnerability would expose the entirety of the congregation's data and not merely the User's session. The browser version operates exclusively in cloud mode.

15.4. For the processing of real congregation data, the Controller recommends the use of the installed versions for macOS, Windows, Android or iOS.

## 16. Security measures

16.1. The Controller has implemented the following administrative, technical and physical security measures:

a) Encryption of information at rest on the device using AES, through SQLite3MultipleCiphers, in the installed versions;
b) Custody of the database key in the operating system's credential store (Keychain, Credential Manager, Keystore), excluding its storage in a plain file;
c) End-to-end encryption of synchronised content using AES-256-GCM, with the scope specified in section 8;
d) Server-side security rules restricting access to each document according to the requester's membership and capabilities;
e) Verification of request authenticity through Firebase App Check;
f) Encryption of communications through TLS;
g) Security headers and a strict content security policy in the web environment;
h) Locking by biometric authentication or system credential, at the User's election.

16.2. Notwithstanding the foregoing, no information system is free from risk. The Controller does not warrant the absolute inviolability of the measures implemented.

## 17. Minors

17.1. Account creation requires that the User be eighteen years of age or older. The Controller does not knowingly create accounts for minors.

17.2. The Participants directory may comprise data of minors, given that minors take part in the meeting program. Such records are created by the User, to whom it falls:

a) To obtain the consent of the holder of parental authority or guardianship;
b) To limit processing to the strict minimum, ordinarily consisting of the display name;
c) To refrain from entering date of birth, notes or any information not necessary for the assignment of parts.

## 18. ARCO rights and procedure for their exercise

18.1. The Data Subject has the right to **access** their personal data, to **rectify** it where inaccurate or incomplete, to **cancel** it where they consider it is not required for the stated purposes, and to **object** to its processing for specific purposes.

18.2. **Procedure.** The request must be addressed to `privacidad@agora.mobi`, from the address associated with the account, and must contain:

a) The Data Subject's name and an address or means for communicating the response;
b) A document evidencing their identity or, where applicable, legal representation;
c) A clear and precise description of the personal data in respect of which the right is exercised;
d) Any element or document facilitating the location of the personal data.

18.3. **Time limits.** The Controller will communicate the determination adopted within a maximum of **twenty business days** from receipt of the request. Where the request is well founded, it will be given effect within the **fifteen business days** following that communication.

18.4. **No charge.** The exercise of ARCO rights is free of charge. Only justified costs of postage or of reproduction on storage media may be passed on.

18.5. **Self-service means.** The Application enables the User to consult, modify and delete all of their content, to export it to a portable file and to delete their account, without the need to submit a request.

18.6. **Requests submitted by Participants.** Pursuant to section 5.3, with respect to Participants' personal data the controller of the processing is the User. Accordingly, requests that a Participant addresses to the Controller in respect of encrypted content for which the Controller is not responsible will be referred to the corresponding User, who has within the Application the means to attend to them.

## 19. Withdrawal of consent

19.1. The Data Subject may withdraw their consent at any time, by the following means:

a) **Diagnostics and analytics:** the Application's settings section. Takes effect immediately;
b) **Cloud synchronisation:** signing out or deleting the account. The Application continues to operate in local mode without loss of information;
c) **All processing:** uninstallation of the Application.

19.2. Withdrawal has no retroactive effect in respect of processing lawfully carried out beforehand.

## 20. Limitation of use and disclosure

20.1. In addition to the exercise of ARCO rights, the Data Subject may request the limitation of the use or disclosure of their personal data by communication addressed to `privacidad@agora.mobi`.

20.2. The Controller does not participate in public or private advertising exclusion registries, given that it carries out no processing for marketing purposes.

## 21. Data Subjects located outside the United Mexican States

21.1. The Application is operated from the United Mexican States and is available in other jurisdictions.

21.2. In respect of Data Subjects located in the European Economic Area, the United Kingdom, the Federative Republic of Brazil or another jurisdiction recognising additional rights, the Controller recognises the rights of access, rectification, erasure, restriction of processing, objection, portability and not to be subject to automated individual decisions, exercisable through the channel indicated in section 18.2.

21.3. For Data Subjects subject to the General Data Protection Regulation of the European Union, the legal bases for processing are: **performance of the contract** in respect of the primary purposes; **consent** in respect of the secondary purposes; and **legitimate interest** in maintaining the security of the service. Data relating to religious beliefs referred to in Article 9 of that Regulation is entered by the User in their capacity as controller, and it falls to the User to establish the applicability of one of the cases set out in Article 9(2).

## 22. Cookies and storage technologies

22.1. The site `agora.mobi` employs no advertising cookies, third-party cookies or technologies for tracking, monitoring or interaction mapping.

22.2. The browser version of the Application employs browser storage mechanisms (IndexedDB and `localStorage`) to retain the database, the session and the User's preferences. Such storage is strictly necessary for the operation of the Application; clearing it results in the closing of the session and the deletion of the local information.

## 23. Security breaches

23.1. In the event of a security breach materially affecting the property or moral rights of Data Subjects, the Controller will notify it without delay by communication to the email address associated with the account and by publication at `agora.mobi`.

23.2. The notification will comprise: the nature of the incident, the personal data compromised, the corrective actions implemented and the recommendations addressed to the Data Subject.

23.3. In the case of Users in local mode in respect of whom the Controller holds no contact details, notification will be made by publication on the site.

## 24. Amendments to this Privacy Notice

24.1. The Controller may amend this Privacy Notice. Substantial amendments — consisting of the addition of new purposes, the addition of new processors or the modification of the encryption scheme — will be communicated through the Application and the site `agora.mobi/privacidad` with not less than **thirty calendar days'** notice, the preceding version remaining accessible.

24.2. The Controller will not extend the purposes of processing of personal data previously collected without prior communication to the Data Subject on the terms of the foregoing section.

## 25. Supervisory authority

25.1. A Data Subject who considers their right to the protection of personal data to have been infringed may apply to the **Secretaría Anticorrupción y Buen Gobierno**, in its capacity as the competent authority under the Law.

## 26. Contact

Vicente Nevarez Treviño
`[ADDRESS]`
`privacidad@agora.mobi`
