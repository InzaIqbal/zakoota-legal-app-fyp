// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Zakoota';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageUrdu => 'Urdu';

  @override
  String get accept => 'Accept';

  @override
  String get cancel => 'Cancel';

  @override
  String get skip => 'Skip';

  @override
  String get getStarted => 'Get Started';

  @override
  String get next => 'Next';

  @override
  String get appBrand => 'Zakoota';

  @override
  String get appTagline => 'Legal Services Marketplace';

  @override
  String get findVerifiedLawyers => 'Find Verified Lawyers';

  @override
  String get connectWithTopExperts =>
      'Connect with top legal experts instantly.';

  @override
  String get trackYourCase => 'Track Your Case';

  @override
  String get realtimeUpdates => 'Real-time updates on hearings and documents.';

  @override
  String get securePayments => 'Secure Payments';

  @override
  String get escrowProtection => 'Escrow protection for your peace of mind.';

  @override
  String get welcomeTitle => 'Welcome to Zakoota';

  @override
  String get chooseYourRole => 'Choose your role to continue';

  @override
  String get iAmClient => 'I am a Client';

  @override
  String get iNeedLegalHelp => 'I need legal help.';

  @override
  String get iAmLawyer => 'I am a Lawyer';

  @override
  String get iWantToFindCases => 'I want to find cases.';

  @override
  String get createAccountTitle => 'Create Account';

  @override
  String get letsGetStarted => 'Let\'s get started';

  @override
  String get createAccountDescription =>
      'Create an account to find the best lawyers.';

  @override
  String get fullNameLabel => 'Full Name';

  @override
  String get pleaseEnterYourName => 'Please enter your name';

  @override
  String get emailAddressLabel => 'Email Address';

  @override
  String get pleaseEnterYourEmailAddress => 'Please enter your email address';

  @override
  String get createAccountButton => 'Create Account';

  @override
  String get signUpWithGoogle => 'Sign up with Google';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get logIn => 'Log In';

  @override
  String get ageLabel => 'Age';

  @override
  String get pleaseEnterYourAge => 'Please enter your age';

  @override
  String get must18Plus => 'Must be 18 or above';

  @override
  String get addressLabel => 'Address';

  @override
  String get pleaseEnterAddress => 'Please enter address';

  @override
  String get professionLabel => 'Profession';

  @override
  String get selectProfession => 'Please select a profession';

  @override
  String get professionStudent => 'Student';

  @override
  String get professionBusinessOwner => 'Business Owner';

  @override
  String get professionEmployee => 'Employee';

  @override
  String get professionHousewife => 'Housewife';

  @override
  String get professionOther => 'Other';

  @override
  String get cnicNumberLabel => 'CNIC Number';

  @override
  String get cnicNumberHint => 'XXXXX-XXXXXXX-X';

  @override
  String get pleaseEnterCnic => 'Please enter CNIC';

  @override
  String get invalidCnicFormat => 'Invalid format (13 digits)';

  @override
  String get pleaseProfession => 'Please select a profession.';

  @override
  String get nextVerifyIdentity => 'Next: Verify Identity';

  @override
  String get profileSetupTitle => 'Complete Profile';

  @override
  String get profileSetupStep1of2 => 'Step 1 of 2';

  @override
  String get tellUsAboutYourself => 'Tell us about yourself';

  @override
  String get provideDetailsToVerify =>
      'Please provide your details to proceed with verification.';

  @override
  String get orContinueWith => 'Or continue with';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get signUpFailedPrefix => 'Sign up failed:';

  @override
  String get googleSignInFailedPrefix => 'Google sign in failed:';

  @override
  String get clientAccountRedirecting =>
      'This account is a client account. You are being redirected...';

  @override
  String get invalidCredentialsMessage =>
      'Invalid credentials. Please check your email and password.';

  @override
  String accountRedirecting(Object role, Object roleLabel) {
    return 'This account is a $role account. You are being redirected...';
  }

  @override
  String get lawyerRegistration => 'Lawyer Registration';

  @override
  String get lawyerRegistrationDescription =>
      'Create your professional account to start accepting cases.';

  @override
  String get exampleName => 'e.g. John Doe';

  @override
  String get exampleEmail => 'name@example.com';

  @override
  String get pleaseEnterYourFullName => 'Please enter your full name';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get alreadyHaveAccountQuestion => 'Already have an account?';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailHint => 'Enter your email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get pleaseEnterPassword => 'Please enter password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get forgotPasswordComingSoon => 'Forgot Password - Coming soon';

  @override
  String get loginButton => 'Log In';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get signUp => 'Sign Up';

  @override
  String get signInTitle => 'Sign In';

  @override
  String continueAs(Object role) {
    return 'Continue as $role';
  }

  @override
  String get pleaseEnterYourEmail => 'Please enter your email';

  @override
  String get pleaseEnterValidEmail => 'Please enter a valid email';

  @override
  String get pleaseEnterYourPassword => 'Please enter your password';

  @override
  String passwordMinLength(Object min) {
    return 'Password must be at least $min characters';
  }

  @override
  String get bookings => 'Bookings';

  @override
  String get myCases => 'My Cases';

  @override
  String get consultations => 'Consultations';

  @override
  String get noConsultationsYet => 'No consultations yet';

  @override
  String get loginToViewConsultations => 'Please log in to view consultations.';

  @override
  String get loginToViewCases => 'Please log in to view your cases.';

  @override
  String get caseNotFound => 'Case Not Found';

  @override
  String get caseDetailsNotAvailable => 'Case details not available';

  @override
  String get caseLabel => 'Case';

  @override
  String get overview => 'Overview';

  @override
  String get timeline => 'Timeline';

  @override
  String get documents => 'Documents';

  @override
  String statusLabel(Object status) {
    return 'Status: $status';
  }

  @override
  String filedOn(Object date) {
    return 'Filed on $date';
  }

  @override
  String get upcomingHearing => 'Upcoming Hearing';

  @override
  String get addToCalendarComingSoon => 'Add to Calendar - Coming soon';

  @override
  String get addToCalendar => 'Add to Calendar';

  @override
  String get assignedLawyer => 'Assigned Lawyer';

  @override
  String get publishAd => 'Publish Ad';

  @override
  String get dismiss => 'Dismiss';

  @override
  String bookingsCount(Object count) {
    return '$count bookings';
  }

  @override
  String createdDate(Object date) {
    return 'Created $date';
  }

  @override
  String get adUpdatedSuccessfully => 'Ad updated successfully';

  @override
  String get adPublishedSuccessfully => 'Ad published successfully';

  @override
  String get failedToSaveAd => 'Failed to save ad';

  @override
  String get editServiceAd => 'Edit Service Ad';

  @override
  String get createNewService => 'Create New Service';

  @override
  String get basicInformation => 'Basic Information';

  @override
  String get adTitle => 'Ad Title';

  @override
  String get exampleAdTitle => 'e.g. Criminal Defense Consultation';

  @override
  String get titleIsRequired => 'Title is required';

  @override
  String get description => 'Description';

  @override
  String get describeYourService => 'Describe your service in detail...';

  @override
  String get descriptionIsRequired => 'Description is required';

  @override
  String get practiceArea => 'Practice Area';

  @override
  String get pricingAndDuration => 'Pricing & Duration';

  @override
  String get pricingType => 'Pricing Type';

  @override
  String get fixedPrice => 'Fixed Price';

  @override
  String get perHour => 'Per Hour';

  @override
  String get pricePkr => 'Price (PKR)';

  @override
  String get enterValidPrice => 'Enter valid price';

  @override
  String get estimatedDuration => 'Estimated Duration';

  @override
  String get exampleDuration => 'e.g. 1-2 weeks, 3 sessions';

  @override
  String get durationIsRequired => 'Duration is required';

  @override
  String get locationAndRequirements => 'Location & Requirements';

  @override
  String get serviceMode => 'Service Mode';

  @override
  String get requiredClientDocuments => 'Required Client Documents';

  @override
  String get exampleRequiredDocs =>
      'e.g. CNIC, FIR copy, property docs (comma-separated)';

  @override
  String get pleaseListRequiredDocuments => 'Please list required documents';

  @override
  String get createAd => 'Create Ad';

  @override
  String get activeCasesLimit => 'Active Cases Limit';

  @override
  String activeCasesInUse(Object count) {
    return '$count/5 active cases are currently in use.';
  }

  @override
  String get adsPausedDueToLimit =>
      'Your ads are paused because you reached the 5 active cases limit.';

  @override
  String get totalAds => 'Total Ads';

  @override
  String get active => 'Active';

  @override
  String get yourAds => 'Your Ads';

  @override
  String get editDetails => 'Edit Details';

  @override
  String get activateAd => 'Activate Ad';

  @override
  String deleteAdConfirm(Object title) {
    return 'Are you sure you want to delete \"$title\"? This action cannot be undone.';
  }

  @override
  String get cannotReactivateAd => 'Cannot Reactivate Ad';

  @override
  String get cannotReactivateAdMessage =>
      'You have reached the maximum of 5 active cases. Complete or close some cases before reactivating ads.';

  @override
  String get refineResults => 'Refine Results';

  @override
  String get sortBy => 'Sort By';

  @override
  String get newest => 'Newest';

  @override
  String get budgetHighToLow => 'Budget: High to Low';

  @override
  String get budgetLowToHigh => 'Budget: Low to High';

  @override
  String get jobType => 'Job Type';

  @override
  String get corporate => 'Corporate';

  @override
  String get criminal => 'Criminal';

  @override
  String get civil => 'Civil';

  @override
  String get property => 'Property';

  @override
  String get family => 'Family';

  @override
  String get budgetRangePkr => 'Budget Range (PKR)';

  @override
  String get zeroK => '0k';

  @override
  String get thousandKPlus => '1000k+';

  @override
  String get showResults => 'Show Results';

  @override
  String get findWork => 'Find Work';

  @override
  String get searchJobs => 'Search jobs...';

  @override
  String get filter => 'Filter';

  @override
  String get noJobsFound => 'No jobs found';

  @override
  String get pleaseLoginToSubmitProposal => 'Please login to submit a proposal';

  @override
  String get pleaseFillAllFields => 'Please fill all fields';

  @override
  String get lawyer => 'Lawyer';

  @override
  String get unknown => 'Unknown';

  @override
  String get proposalSubmittedSuccessfully =>
      'Proposal submitted successfully!';

  @override
  String get jobDetails => 'Job Details';

  @override
  String get details => 'Details';

  @override
  String get proposals => 'Proposals';

  @override
  String get jobDescription => 'Job Description';

  @override
  String get attachments => 'Attachments';

  @override
  String get aboutTheClient => 'About the Client';

  @override
  String joined(Object date) {
    return 'Joined $date';
  }

  @override
  String get memberSince2024 => 'Member since 2024';

  @override
  String get proposalSubmitted => 'Proposal Submitted';

  @override
  String get proposalAlreadySubmitted =>
      'You have already submitted a proposal for this job. You can edit it below.';

  @override
  String get submitAProposal => 'Submit a Proposal';

  @override
  String get bidAmountPkr => 'Bid Amount (PKR)';

  @override
  String get example50000 => 'e.g. 50000';

  @override
  String get duration => 'Duration';

  @override
  String get example7Days => 'e.g. 7 Days';

  @override
  String get coverLetter => 'Cover Letter';

  @override
  String get describeWhyYouAreBestFit =>
      'Describe why you are the best fit for this job...';

  @override
  String get submitProposal => 'Submit Proposal';

  @override
  String get noProposalsYet => 'No proposals yet';

  @override
  String get beTheFirstToSubmit => 'Be the first to submit a proposal!';

  @override
  String get deleteProposal => 'Delete Proposal?';

  @override
  String get deleteProposalConfirm =>
      'Are you sure you want to delete this proposal? This action cannot be undone.';

  @override
  String get delete => 'Delete';

  @override
  String get proposalDeleted => 'Proposal deleted';

  @override
  String get editProposal => 'Edit Proposal';

  @override
  String get bidAmount => 'Bid Amount';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get proposalUpdated => 'Proposal updated';

  @override
  String get error => 'Error';

  @override
  String get pleaseLoginToManageAds => 'Please login to manage ads';

  @override
  String get manageAds => 'Manage Ads';

  @override
  String get newAd => 'New Ad';

  @override
  String get errorLoadingAds => 'Error loading ads';

  @override
  String get noAdsYet => 'No Ads Yet';

  @override
  String get createYourFirstAdToAttractClients =>
      'Create your first ad to attract clients.';

  @override
  String get postACase => 'Post a Case';

  @override
  String get caseDetails => 'Case Details';

  @override
  String get caseTitleLabel => 'Case Title';

  @override
  String get caseTitleHint => 'Enter case title';

  @override
  String get pleaseEnterCaseTitle => 'Please enter case title';

  @override
  String titleMinLength(Object min) {
    return 'Title must be at least $min characters';
  }

  @override
  String get categoryLabel => 'Category';

  @override
  String get pleaseSelectCategory => 'Please select a category';

  @override
  String get cityLabel => 'City';

  @override
  String get cityHint => 'Enter city';

  @override
  String get pleaseEnterCity => 'Please enter city';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get descriptionHint => 'Describe the case';

  @override
  String get pleaseDescribeCase => 'Please describe the case';

  @override
  String descriptionMinLength(Object min) {
    return 'Description must be at least $min characters';
  }

  @override
  String get tapToUploadDocuments => 'Tap to upload documents';

  @override
  String get pdfWordImages => 'PDF, Word, images';

  @override
  String get postingCase => 'Posting case...';

  @override
  String get noLawyerAssignedYet => 'No lawyer assigned yet';

  @override
  String get message => 'Message';

  @override
  String get caseDescription => 'Case Description';

  @override
  String get legalJourney => 'The Legal Journey';

  @override
  String get dashboardRefreshed => 'Dashboard refreshed';

  @override
  String get welcomeBackComma => 'Welcome back,';

  @override
  String get todaysAgenda => 'Today\'s Agenda';

  @override
  String get allCaughtUp => 'All caught up!';

  @override
  String get noUrgentEventsToday =>
      'No urgent events or hearings today. Take your day seriously.';

  @override
  String get consultationEvent => 'Consultation';

  @override
  String get hearingEvent => 'Hearing';

  @override
  String get workspaceEvent => 'Workspace Event';

  @override
  String get openWorkspaceEvent => 'Open Workspace Event';

  @override
  String get noActiveCasesYetApplyToJobs =>
      'No active cases yet.\nApply to jobs to find work!';

  @override
  String get openWorkspace => 'Open Workspace';

  @override
  String get noScheduledConsultations => 'No scheduled consultations';

  @override
  String get videoCall => 'Video Call';

  @override
  String get inPerson => 'In-Person';

  @override
  String get clientLabel => 'Client';

  @override
  String get idLabel => 'ID:';

  @override
  String budgetRange(Object max, Object min) {
    return 'Budget: $min - $max';
  }

  @override
  String withLabel(Object name) {
    return 'With: $name';
  }

  @override
  String timeLabel(Object time) {
    return 'Time: $time';
  }

  @override
  String get respond => 'Respond';

  @override
  String get goToWorkspaceToRespondToConsultation =>
      'Go to workspace to respond to consultation';

  @override
  String get cancelConsultation => 'Cancel Consultation';

  @override
  String get areYouSureWantToCancelConsultation =>
      'Are you sure you want to cancel this consultation?';

  @override
  String get no => 'No';

  @override
  String get consultationCancelled => 'Consultation cancelled';

  @override
  String get cancelledByLawyer => 'Cancelled by lawyer';

  @override
  String get acceptedStatus => 'Accepted';

  @override
  String get pendingStatus => 'Pending';

  @override
  String get rejectedStatus => 'Rejected';

  @override
  String get cancelledStatus => 'Cancelled';

  @override
  String get completedStatus => 'Completed';

  @override
  String get noShowStatus => 'No Show';

  @override
  String get activeCases => 'Active Cases';

  @override
  String get noActiveCases => 'No active cases';

  @override
  String get postNewCaseToGetStarted => 'Post a new case to get started.';

  @override
  String get untitledCase => 'Untitled Case';

  @override
  String get recentUpdates => 'Recent Updates';

  @override
  String get noRecentUpdatesYet => 'No recent updates yet';

  @override
  String get viewDetails => 'View Details';

  @override
  String get availabilitySettings => 'Availability Settings';

  @override
  String get walletBalance => 'Wallet Balance';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get postAd => 'Post Ad';

  @override
  String get withdraw => 'Withdraw';

  @override
  String get calendar => 'Calendar';

  @override
  String get analytics => 'Analytics';

  @override
  String get myActiveAds => 'My Active Ads';

  @override
  String get viewAll => 'View All';

  @override
  String get noActiveAdsYet => 'No active ads yet';

  @override
  String get newJobMatches => 'New Job Matches';

  @override
  String get createFirstAdHint =>
      'Create your first ad from quick actions to appear in client search.';

  @override
  String get explore => 'Explore';

  @override
  String get noJobMatchesFound => 'No job matches available right now.';

  @override
  String get pauseAd => 'Pause Ad';

  @override
  String get resumeAd => 'Resume Ad';

  @override
  String get deleteAd => 'Delete Ad';

  @override
  String get uploadBothCnicAndSelfie =>
      'Please upload both CNIC and selfie to proceed.';

  @override
  String get verifyIdentityTitle => 'Verify Identity';

  @override
  String get identityVerification => 'Identity Verification';

  @override
  String get uploadCnicAndSelfie => 'Please upload your CNIC and a selfie.';

  @override
  String get cnicFrontLabel => 'CNIC (Front)';

  @override
  String get yourSelfieLabel => 'Your Selfie';

  @override
  String get uploading => 'Uploading...';

  @override
  String get submitVerification => 'Submit Verification';

  @override
  String tapToUpload(Object label) {
    return 'Tap to upload $label';
  }

  @override
  String get legalServices => 'Legal Services';

  @override
  String get findLawyers => 'Find Lawyers';

  @override
  String get documentReview => 'Document Review';

  @override
  String get legalArticles => 'Legal Articles';

  @override
  String get lawyerNotFound => 'Lawyer not found';

  @override
  String get bookConsultation => 'Book Consultation';

  @override
  String get lawyerFocus => 'Lawyer Focus';

  @override
  String get topicBriefDescription => 'Topic / Brief Description';

  @override
  String get consultationHint => 'What is this consultation about?';

  @override
  String get meetingPreference => 'Meeting Preference';

  @override
  String get selectDate => 'Select Date';

  @override
  String get selectTime => 'Select Time';

  @override
  String get pleaseSelectDateFirst => 'Please select a date first';

  @override
  String get totalLabel => 'Total';

  @override
  String get reviewAndPay => 'Review & Pay';

  @override
  String get currencyPKR => 'PKR';

  @override
  String get profileTitle => 'Profile';

  @override
  String get retry => 'Retry';

  @override
  String get verifiedLawyer => 'Verified Lawyer';

  @override
  String get yearsExperience => 'Years Exp';

  @override
  String get casesWon => 'Cases Won';

  @override
  String get ratingLabel => 'Rating';

  @override
  String get aboutMe => 'About Me';

  @override
  String get specializationsLabel => 'Specializations';

  @override
  String get educationAndCredentials => 'Education & Credentials';

  @override
  String get clientReviews => 'Client Reviews';

  @override
  String reviewsCount(Object count) {
    return '$count reviews';
  }

  @override
  String get workplaceTitle => 'Work Place';

  @override
  String get files => 'Files';

  @override
  String get events => 'Events';

  @override
  String get milestones => 'Milestones';

  @override
  String get invoices => 'Invoices';

  @override
  String get partnerDetailsNotFound => 'Partner details not found';

  @override
  String get client => 'Client';

  @override
  String get yearsExperienceShort => 'yrs exp';

  @override
  String get fundsInCustody => 'Funds in Custody';

  @override
  String get status => 'Status';

  @override
  String get heldInSystemCustody => 'Held in system custody';

  @override
  String get heldAmount => 'Held Amount';

  @override
  String get caseSummary => 'Case Summary';

  @override
  String get projectDetails => 'Project Details';

  @override
  String get location => 'Location';

  @override
  String get budget => 'Budget';

  @override
  String get agreedWithLawyer => 'Agreed with Lawyer';

  @override
  String get clientRange => 'Client Range';

  @override
  String get inPersonMeeting => 'In-Person Meeting';

  @override
  String get virtualOnline => 'Virtual / Online';

  @override
  String get timelineAndStatus => 'Timeline & Status';

  @override
  String get createdOn => 'Created On';

  @override
  String get caseCompletedSuccessfully => 'Case Completed Successfully';

  @override
  String get waitingForClientToVerifyWork =>
      'Waiting for Client to verify work...';

  @override
  String get workApprovedWaitingForPaymentRelease =>
      'Work approved! Waiting for payment release...';

  @override
  String get finishWorkSignalClient =>
      'Have you finished the work? Send a signal to the client to verify and release payment.';

  @override
  String get signalWorkDone => 'Signal Work Done';

  @override
  String get lawyerMarkedWorkDoneVerify =>
      'Lawyer has marked the work as done. Please verify if you are satisfied.';

  @override
  String get stillPending => 'Still Pending';

  @override
  String get workApproved => 'Work Approved';

  @override
  String get workApprovedRateAndRelease =>
      'Work approved! Please rate the lawyer and release the payment to close the case.';

  @override
  String get rateAndReleasePayment => 'Rate & Release Payment';

  @override
  String get currentStatus => 'Current Status';

  @override
  String get currentlyActiveWorkspace => 'Currently Active (Workspace)';

  @override
  String get caseClosedCompleted => 'Case Closed / Completed';

  @override
  String get requestConsultation => 'Request Consultation';

  @override
  String get noConsultationsScheduledYet =>
      'No consultations scheduled yet.\nRequest one above!';

  @override
  String get partnerLabel => 'Partner';

  @override
  String get reject => 'Reject';

  @override
  String get uploadFile => 'Upload File';

  @override
  String get originalAttachment => 'Original Attachment';

  @override
  String get noFilesSharedYet => 'No files shared yet.\nUpload documents here!';

  @override
  String get uploadedByClientInitial => 'Uploaded by Client (Initial)';

  @override
  String get uploadedByClient => 'Uploaded by Client';

  @override
  String get uploadedByLawyer => 'Uploaded by Lawyer';

  @override
  String get addEvent => 'Add Event';

  @override
  String get onlyLawyerCanAddEvents =>
      'Only lawyer can add events. You can view all updates here.';

  @override
  String get noCaseEventsYet =>
      'No case events yet.\nLawyer can add updates here.';

  @override
  String get place => 'Place';

  @override
  String get time => 'Time';

  @override
  String get addMilestoneTask => 'Add Milestone / Task';

  @override
  String get noMilestonesYet =>
      'No milestones yet.\nAdd tasks to keep progress clear.';

  @override
  String get due => 'Due';

  @override
  String get noDueDate => 'No due date';

  @override
  String availableSlotsForDate(Object date) {
    return 'Available slots for $date';
  }

  @override
  String get noAvailableSlotsMessage =>
      'No available slots on this date. Try a different day or duration.';

  @override
  String get videoMeetingDetails => 'Video Meeting Details';

  @override
  String get meetingLinkHint => 'Meeting link (Zoom, Google Meet, etc.)';

  @override
  String get meetingLocation => 'Meeting Location';

  @override
  String get meetingLocationHint => 'Address or location details';

  @override
  String get additionalNotesOptional => 'Additional Notes (Optional)';

  @override
  String get additionalNotesHint =>
      'Any special instructions or requirements...';

  @override
  String get sendRequest => 'Send Request';

  @override
  String get pleaseEnterConsultationTopic =>
      'Please enter a consultation topic';

  @override
  String get lawyerNotAvailable =>
      'Lawyer is not available at the selected time';

  @override
  String get timeSlotConflictMessage =>
      'Another consultation is already booked for this time slot';

  @override
  String get consultationRequestSent => 'Consultation request sent!';

  @override
  String get signalCompletionTitle => 'Signal Completion?';

  @override
  String get signalCompletionMessage =>
      'Answering \"Yes\" will notify the client that the work is finished and ask them to verify it.';

  @override
  String get completionSignalSentToClient => 'Completion signal sent to client';

  @override
  String get approveWorkTitle => 'Approve Work?';

  @override
  String get rejectCompletionTitle => 'Reject Completion?';

  @override
  String get approveWorkMessage =>
      'Are you sure you want to approve this work? You will be asked to rate and pay next.';

  @override
  String get rejectCompletionMessage =>
      'Are you sure the work is not done? This will signal the lawyer to continue working.';

  @override
  String get yesApprove => 'Yes, Approve';

  @override
  String get yesWorkPending => 'Yes, Work is Pending';

  @override
  String get rejectionSentToLawyer => 'Rejection sent to lawyer';

  @override
  String get rateLawyerTitle => 'Rate Lawyer';

  @override
  String get writeReviewHint => 'Write a review...';

  @override
  String get submitReviewAndContinue => 'Submit Review & Continue';

  @override
  String get failedToSubmitReview => 'Failed to submit review';

  @override
  String get releasePaymentTitle => 'Release Payment';

  @override
  String get releasePaymentDescription =>
      'The work is approved and reviewed. Now release the agreed payment to the lawyer.';

  @override
  String get agreedAmountLabel => 'Agreed Amount:';

  @override
  String get releasePaymentAction => 'Release Payment';

  @override
  String get paymentReleasedAndCaseCompleted =>
      'Payment released! Case marked as completed.';

  @override
  String get paymentFailed => 'Payment failed';

  @override
  String get paymentAmountLabel => 'Payment Amount';

  @override
  String get paymentReleasedSuccessfully => 'Payment released successfully';

  @override
  String get releaseFailed => 'Release failed';

  @override
  String get processing => 'Processing...';

  @override
  String get release => 'Release';

  @override
  String get pay => 'Pay';

  @override
  String get createInvoice => 'Create Invoice';

  @override
  String get noInvoicesYet =>
      'No invoices yet.\nLawyer can create payment requests here.';

  @override
  String get titleLabel => 'Title';

  @override
  String get milestoneTitleHint => 'e.g., Draft petition and review';

  @override
  String get detailsLabel => 'Details';

  @override
  String get optionalTaskNotesHint => 'Optional notes for this task';

  @override
  String get paymentAmountPKRLabel => 'Payment Amount (PKR)';

  @override
  String get optionalLeaveEmptyIfNoPaymentRequired =>
      'Optional - leave empty if no payment required';

  @override
  String get setDueDateOptional => 'Set Due Date (Optional)';

  @override
  String get add => 'Add';

  @override
  String get taskTitleRequired => 'Task title is required';

  @override
  String get newMilestoneAdded => 'New milestone added';

  @override
  String get milestoneAddedSuccessfully => 'Milestone added successfully';

  @override
  String get milestoneMarkedCompleted => 'Milestone marked as completed';

  @override
  String get milestoneReopened => 'Milestone reopened';

  @override
  String get invoiceTitleLabel => 'Invoice Title';

  @override
  String get invoiceTitleHint => 'e.g., Filing fee - stage 1';

  @override
  String get amountPKRLabel => 'Amount (PKR)';

  @override
  String get amountHint => 'e.g., 15000';

  @override
  String get notesLabel => 'Notes';

  @override
  String get optionalPaymentDetailsHint => 'Optional payment details';

  @override
  String get titleAndValidAmountRequired =>
      'Title and a valid amount are required';

  @override
  String get newInvoiceCreated => 'New invoice created';

  @override
  String get invoiceSentToClient => 'Invoice sent to client';

  @override
  String get invoiceCreatedSuccessfully => 'Invoice created successfully';

  @override
  String get onlyPayerCanMarkInvoicePaid => 'Only payer can mark invoice paid';

  @override
  String insufficientBalanceForInvoice(Object available, Object required) {
    return 'Insufficient balance. Available: PKR $available, Required: PKR $required';
  }

  @override
  String get invoiceReleased => 'Invoice released';

  @override
  String get invoiceHeld => 'Invoice held';

  @override
  String invoiceReleasedToLawyer(Object title) {
    return '$title has been released to the lawyer';
  }

  @override
  String invoiceHeldInEscrow(Object title) {
    return '$title has been held in escrow';
  }

  @override
  String get invoiceReleasedByClient => 'Invoice released by client';

  @override
  String get invoicePaymentHeld => 'Invoice payment held';

  @override
  String invoiceReleasedByClientMessage(Object title) {
    return '$title has been released by the client';
  }

  @override
  String invoicePaymentHeldMessage(Object title) {
    return '$title has been held in escrow by the client';
  }

  @override
  String invoiceReleaseCompleted(Object title) {
    return '$title release completed';
  }

  @override
  String invoicePaymentHeldInEscrow(Object title) {
    return '$title payment held in escrow';
  }

  @override
  String invoiceMarkedReleasedInWorkspace(Object title) {
    return '$title marked released in workspace';
  }

  @override
  String invoiceHeldInWorkspace(Object title) {
    return '$title held in workspace';
  }

  @override
  String get invoiceUpdatedSuccessfully => 'Invoice updated successfully';

  @override
  String get paid => 'Paid';

  @override
  String get held => 'Held';

  @override
  String get upcoming => 'Upcoming';

  @override
  String get completed => 'Completed';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get qualityOfWork => 'Quality of Work';

  @override
  String get budgetAdjustment => 'Budget Adjustment';

  @override
  String get wayOfTalking => 'Way of Talking';

  @override
  String get promptness => 'Promptness';

  @override
  String get expertise => 'Expertise';

  @override
  String get onlyClientCanPayMilestone => 'Only client can pay milestone';

  @override
  String get milestoneAlreadyPaid => 'This milestone is already paid';

  @override
  String insufficientBalanceForMilestone(Object available, Object required) {
    return 'Insufficient balance. Available: PKR $available, Required: PKR $required';
  }

  @override
  String milestonePaymentReason(Object title) {
    return 'Milestone payment: $title';
  }

  @override
  String get milestonePaymentHeld => 'Milestone payment held';

  @override
  String milestonePaymentHeldMessage(Object amount, Object title) {
    return 'PKR $amount held in escrow for \"$title\"';
  }

  @override
  String get milestonePaymentAwaitingRelease =>
      'Milestone payment awaiting release';

  @override
  String milestonePaymentAwaitingReleaseMessage(Object amount, Object title) {
    return 'PKR $amount is held in escrow for \"$title\"';
  }

  @override
  String milestonePaymentHeldInEscrow(Object amount) {
    return 'Payment of PKR $amount held in escrow';
  }

  @override
  String paymentFailedWithDetails(Object details) {
    return 'Payment failed: $details';
  }

  @override
  String get addCaseEvent => 'Add Case Event';

  @override
  String get eventNameLabel => 'Event Name';

  @override
  String get eventNameHint => 'e.g., Court Hearing';

  @override
  String get eventPlaceLabel => 'Event Place';

  @override
  String get eventPlaceHint => 'e.g., District Court Lahore';

  @override
  String get eventNameAndPlaceRequired => 'Event name and place are required';

  @override
  String get createEvent => 'Create Event';

  @override
  String get cannotCreateEventForThisCase =>
      'Cannot create event for this case';

  @override
  String caseEventMessage(Object eventName, Object place, Object time) {
    return '$eventName at $place on $time';
  }

  @override
  String get newCaseEventAdded => 'New case event added';

  @override
  String get eventCreatedSuccessfully => 'Event created successfully';

  @override
  String get newEventScheduled => 'New event scheduled';

  @override
  String get eventAddedToCase => 'Event added to case';

  @override
  String get eventAddedAndUsersNotified => 'Event added and users notified';

  @override
  String get uploadLimitReached =>
      'Upload limit reached (Max 3 files per party)';

  @override
  String get maxFilesPerParty => 'Max 3 files per party';

  @override
  String get fileUploadedSuccessfully => 'File uploaded successfully!';

  @override
  String get errorUploadingFile => 'Error uploading file';

  @override
  String get nameYourFile => 'Name your file';

  @override
  String get fileNameLabel => 'File Name';

  @override
  String get fileNameHint => 'Enter name for other party to see';

  @override
  String get upload => 'Upload';

  @override
  String get renameFile => 'Rename file';

  @override
  String get newNameLabel => 'New Name';

  @override
  String get save => 'Save';

  @override
  String get fileRenamed => 'File renamed';

  @override
  String get renameFailed => 'Rename failed';

  @override
  String get deleteFileTitle => 'Delete File?';

  @override
  String deleteFileConfirm(Object fileName) {
    return 'Are you sure you want to delete \"$fileName\"? This action cannot be undone.';
  }

  @override
  String get fileDeleted => 'File deleted';

  @override
  String get deleteFailed => 'Delete failed';

  @override
  String get couldNotOpenFile =>
      'Could not open file. No application found to handle this link.';

  @override
  String get errorOpeningFile => 'Error opening file';

  @override
  String get noLawyerOfficeLocationSet =>
      'No lawyer office location set. Please agree on location via chat.';

  @override
  String get selectedTimeAlreadyPassed =>
      'Selected time has already passed. Please choose a future time.';

  @override
  String get pleaseSelectFutureConsultationDateTime =>
      'Please select a future date and time for consultation.';

  @override
  String get selectedTimeOutsideLawyerAvailability =>
      'Selected time is outside the lawyer\'s availability.';

  @override
  String get selectedTimeConflictsWithAnotherConsultation =>
      'Selected time conflicts with another consultation.';

  @override
  String get consultationLimitReached => 'Consultation Limit Reached';

  @override
  String get consultationLimitReachedDescription =>
      'Each workspace includes 3 free consultations. You have reached this limit. Please pay to schedule more.';

  @override
  String get paymentGatewayComingSoon => 'Payment gateway coming soon...';

  @override
  String get payForOneMore => 'Pay for 1 More (\$10)';

  @override
  String get noUserLoggedIn => 'No user logged in';
}
