import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ur.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ur')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Zakoota'**
  String get appTitle;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageUrdu.
  ///
  /// In en, this message translates to:
  /// **'Urdu'**
  String get languageUrdu;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @appBrand.
  ///
  /// In en, this message translates to:
  /// **'Zakoota'**
  String get appBrand;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Legal Services Marketplace'**
  String get appTagline;

  /// No description provided for @findVerifiedLawyers.
  ///
  /// In en, this message translates to:
  /// **'Find Verified Lawyers'**
  String get findVerifiedLawyers;

  /// No description provided for @connectWithTopExperts.
  ///
  /// In en, this message translates to:
  /// **'Connect with top legal experts instantly.'**
  String get connectWithTopExperts;

  /// No description provided for @trackYourCase.
  ///
  /// In en, this message translates to:
  /// **'Track Your Case'**
  String get trackYourCase;

  /// No description provided for @realtimeUpdates.
  ///
  /// In en, this message translates to:
  /// **'Real-time updates on hearings and documents.'**
  String get realtimeUpdates;

  /// No description provided for @securePayments.
  ///
  /// In en, this message translates to:
  /// **'Secure Payments'**
  String get securePayments;

  /// No description provided for @escrowProtection.
  ///
  /// In en, this message translates to:
  /// **'Escrow protection for your peace of mind.'**
  String get escrowProtection;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Zakoota'**
  String get welcomeTitle;

  /// No description provided for @chooseYourRole.
  ///
  /// In en, this message translates to:
  /// **'Choose your role to continue'**
  String get chooseYourRole;

  /// No description provided for @iAmClient.
  ///
  /// In en, this message translates to:
  /// **'I am a Client'**
  String get iAmClient;

  /// No description provided for @iNeedLegalHelp.
  ///
  /// In en, this message translates to:
  /// **'I need legal help.'**
  String get iNeedLegalHelp;

  /// No description provided for @iAmLawyer.
  ///
  /// In en, this message translates to:
  /// **'I am a Lawyer'**
  String get iAmLawyer;

  /// No description provided for @iWantToFindCases.
  ///
  /// In en, this message translates to:
  /// **'I want to find cases.'**
  String get iWantToFindCases;

  /// No description provided for @createAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccountTitle;

  /// No description provided for @letsGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Let\'s get started'**
  String get letsGetStarted;

  /// No description provided for @createAccountDescription.
  ///
  /// In en, this message translates to:
  /// **'Create an account to find the best lawyers.'**
  String get createAccountDescription;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullNameLabel;

  /// No description provided for @pleaseEnterYourName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get pleaseEnterYourName;

  /// No description provided for @emailAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddressLabel;

  /// No description provided for @pleaseEnterYourEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email address'**
  String get pleaseEnterYourEmailAddress;

  /// No description provided for @createAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccountButton;

  /// No description provided for @signUpWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign up with Google'**
  String get signUpWithGoogle;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get logIn;

  /// No description provided for @ageLabel.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get ageLabel;

  /// No description provided for @pleaseEnterYourAge.
  ///
  /// In en, this message translates to:
  /// **'Please enter your age'**
  String get pleaseEnterYourAge;

  /// No description provided for @must18Plus.
  ///
  /// In en, this message translates to:
  /// **'Must be 18 or above'**
  String get must18Plus;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressLabel;

  /// No description provided for @pleaseEnterAddress.
  ///
  /// In en, this message translates to:
  /// **'Please enter address'**
  String get pleaseEnterAddress;

  /// No description provided for @professionLabel.
  ///
  /// In en, this message translates to:
  /// **'Profession'**
  String get professionLabel;

  /// No description provided for @selectProfession.
  ///
  /// In en, this message translates to:
  /// **'Please select a profession'**
  String get selectProfession;

  /// No description provided for @professionStudent.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get professionStudent;

  /// No description provided for @professionBusinessOwner.
  ///
  /// In en, this message translates to:
  /// **'Business Owner'**
  String get professionBusinessOwner;

  /// No description provided for @professionEmployee.
  ///
  /// In en, this message translates to:
  /// **'Employee'**
  String get professionEmployee;

  /// No description provided for @professionHousewife.
  ///
  /// In en, this message translates to:
  /// **'Housewife'**
  String get professionHousewife;

  /// No description provided for @professionOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get professionOther;

  /// No description provided for @cnicNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'CNIC Number'**
  String get cnicNumberLabel;

  /// No description provided for @cnicNumberHint.
  ///
  /// In en, this message translates to:
  /// **'XXXXX-XXXXXXX-X'**
  String get cnicNumberHint;

  /// No description provided for @pleaseEnterCnic.
  ///
  /// In en, this message translates to:
  /// **'Please enter CNIC'**
  String get pleaseEnterCnic;

  /// No description provided for @invalidCnicFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid format (13 digits)'**
  String get invalidCnicFormat;

  /// No description provided for @pleaseProfession.
  ///
  /// In en, this message translates to:
  /// **'Please select a profession.'**
  String get pleaseProfession;

  /// No description provided for @nextVerifyIdentity.
  ///
  /// In en, this message translates to:
  /// **'Next: Verify Identity'**
  String get nextVerifyIdentity;

  /// No description provided for @profileSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete Profile'**
  String get profileSetupTitle;

  /// No description provided for @profileSetupStep1of2.
  ///
  /// In en, this message translates to:
  /// **'Step 1 of 2'**
  String get profileSetupStep1of2;

  /// No description provided for @tellUsAboutYourself.
  ///
  /// In en, this message translates to:
  /// **'Tell us about yourself'**
  String get tellUsAboutYourself;

  /// No description provided for @provideDetailsToVerify.
  ///
  /// In en, this message translates to:
  /// **'Please provide your details to proceed with verification.'**
  String get provideDetailsToVerify;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get orContinueWith;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @signUpFailedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Sign up failed:'**
  String get signUpFailedPrefix;

  /// No description provided for @googleSignInFailedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Google sign in failed:'**
  String get googleSignInFailedPrefix;

  /// No description provided for @clientAccountRedirecting.
  ///
  /// In en, this message translates to:
  /// **'This account is a client account. You are being redirected...'**
  String get clientAccountRedirecting;

  /// No description provided for @invalidCredentialsMessage.
  ///
  /// In en, this message translates to:
  /// **'Invalid credentials. Please check your email and password.'**
  String get invalidCredentialsMessage;

  /// No description provided for @accountRedirecting.
  ///
  /// In en, this message translates to:
  /// **'This account is a {role} account. You are being redirected...'**
  String accountRedirecting(Object role, Object roleLabel);

  /// No description provided for @lawyerRegistration.
  ///
  /// In en, this message translates to:
  /// **'Lawyer Registration'**
  String get lawyerRegistration;

  /// No description provided for @lawyerRegistrationDescription.
  ///
  /// In en, this message translates to:
  /// **'Create your professional account to start accepting cases.'**
  String get lawyerRegistrationDescription;

  /// No description provided for @exampleName.
  ///
  /// In en, this message translates to:
  /// **'e.g. John Doe'**
  String get exampleName;

  /// No description provided for @exampleEmail.
  ///
  /// In en, this message translates to:
  /// **'name@example.com'**
  String get exampleEmail;

  /// No description provided for @pleaseEnterYourFullName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name'**
  String get pleaseEnterYourFullName;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @alreadyHaveAccountQuestion.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccountQuestion;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get emailHint;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter password'**
  String get pleaseEnterPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @forgotPasswordComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password - Coming soon'**
  String get forgotPasswordComingSoon;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get loginButton;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInTitle;

  /// No description provided for @continueAs.
  ///
  /// In en, this message translates to:
  /// **'Continue as {role}'**
  String continueAs(Object role);

  /// No description provided for @pleaseEnterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterYourEmail;

  /// No description provided for @pleaseEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get pleaseEnterValidEmail;

  /// No description provided for @pleaseEnterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterYourPassword;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least {min} characters'**
  String passwordMinLength(Object min);

  /// No description provided for @bookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get bookings;

  /// No description provided for @myCases.
  ///
  /// In en, this message translates to:
  /// **'My Cases'**
  String get myCases;

  /// No description provided for @consultations.
  ///
  /// In en, this message translates to:
  /// **'Consultations'**
  String get consultations;

  /// No description provided for @noConsultationsYet.
  ///
  /// In en, this message translates to:
  /// **'No consultations yet'**
  String get noConsultationsYet;

  /// No description provided for @loginToViewConsultations.
  ///
  /// In en, this message translates to:
  /// **'Please log in to view consultations.'**
  String get loginToViewConsultations;

  /// No description provided for @loginToViewCases.
  ///
  /// In en, this message translates to:
  /// **'Please log in to view your cases.'**
  String get loginToViewCases;

  /// No description provided for @caseNotFound.
  ///
  /// In en, this message translates to:
  /// **'Case Not Found'**
  String get caseNotFound;

  /// No description provided for @caseDetailsNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Case details not available'**
  String get caseDetailsNotAvailable;

  /// No description provided for @caseLabel.
  ///
  /// In en, this message translates to:
  /// **'Case'**
  String get caseLabel;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @timeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timeline;

  /// No description provided for @documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String statusLabel(Object status);

  /// No description provided for @filedOn.
  ///
  /// In en, this message translates to:
  /// **'Filed on {date}'**
  String filedOn(Object date);

  /// No description provided for @upcomingHearing.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Hearing'**
  String get upcomingHearing;

  /// No description provided for @addToCalendarComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Add to Calendar - Coming soon'**
  String get addToCalendarComingSoon;

  /// No description provided for @addToCalendar.
  ///
  /// In en, this message translates to:
  /// **'Add to Calendar'**
  String get addToCalendar;

  /// No description provided for @assignedLawyer.
  ///
  /// In en, this message translates to:
  /// **'Assigned Lawyer'**
  String get assignedLawyer;

  /// No description provided for @publishAd.
  ///
  /// In en, this message translates to:
  /// **'Publish Ad'**
  String get publishAd;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @bookingsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} bookings'**
  String bookingsCount(Object count);

  /// No description provided for @createdDate.
  ///
  /// In en, this message translates to:
  /// **'Created {date}'**
  String createdDate(Object date);

  /// No description provided for @adUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Ad updated successfully'**
  String get adUpdatedSuccessfully;

  /// No description provided for @adPublishedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Ad published successfully'**
  String get adPublishedSuccessfully;

  /// No description provided for @failedToSaveAd.
  ///
  /// In en, this message translates to:
  /// **'Failed to save ad'**
  String get failedToSaveAd;

  /// No description provided for @editServiceAd.
  ///
  /// In en, this message translates to:
  /// **'Edit Service Ad'**
  String get editServiceAd;

  /// No description provided for @createNewService.
  ///
  /// In en, this message translates to:
  /// **'Create New Service'**
  String get createNewService;

  /// No description provided for @basicInformation.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInformation;

  /// No description provided for @adTitle.
  ///
  /// In en, this message translates to:
  /// **'Ad Title'**
  String get adTitle;

  /// No description provided for @exampleAdTitle.
  ///
  /// In en, this message translates to:
  /// **'e.g. Criminal Defense Consultation'**
  String get exampleAdTitle;

  /// No description provided for @titleIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get titleIsRequired;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @describeYourService.
  ///
  /// In en, this message translates to:
  /// **'Describe your service in detail...'**
  String get describeYourService;

  /// No description provided for @descriptionIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Description is required'**
  String get descriptionIsRequired;

  /// No description provided for @practiceArea.
  ///
  /// In en, this message translates to:
  /// **'Practice Area'**
  String get practiceArea;

  /// No description provided for @pricingAndDuration.
  ///
  /// In en, this message translates to:
  /// **'Pricing & Duration'**
  String get pricingAndDuration;

  /// No description provided for @pricingType.
  ///
  /// In en, this message translates to:
  /// **'Pricing Type'**
  String get pricingType;

  /// No description provided for @fixedPrice.
  ///
  /// In en, this message translates to:
  /// **'Fixed Price'**
  String get fixedPrice;

  /// No description provided for @perHour.
  ///
  /// In en, this message translates to:
  /// **'Per Hour'**
  String get perHour;

  /// No description provided for @pricePkr.
  ///
  /// In en, this message translates to:
  /// **'Price (PKR)'**
  String get pricePkr;

  /// No description provided for @enterValidPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter valid price'**
  String get enterValidPrice;

  /// No description provided for @estimatedDuration.
  ///
  /// In en, this message translates to:
  /// **'Estimated Duration'**
  String get estimatedDuration;

  /// No description provided for @exampleDuration.
  ///
  /// In en, this message translates to:
  /// **'e.g. 1-2 weeks, 3 sessions'**
  String get exampleDuration;

  /// No description provided for @durationIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Duration is required'**
  String get durationIsRequired;

  /// No description provided for @locationAndRequirements.
  ///
  /// In en, this message translates to:
  /// **'Location & Requirements'**
  String get locationAndRequirements;

  /// No description provided for @serviceMode.
  ///
  /// In en, this message translates to:
  /// **'Service Mode'**
  String get serviceMode;

  /// No description provided for @requiredClientDocuments.
  ///
  /// In en, this message translates to:
  /// **'Required Client Documents'**
  String get requiredClientDocuments;

  /// No description provided for @exampleRequiredDocs.
  ///
  /// In en, this message translates to:
  /// **'e.g. CNIC, FIR copy, property docs (comma-separated)'**
  String get exampleRequiredDocs;

  /// No description provided for @pleaseListRequiredDocuments.
  ///
  /// In en, this message translates to:
  /// **'Please list required documents'**
  String get pleaseListRequiredDocuments;

  /// No description provided for @createAd.
  ///
  /// In en, this message translates to:
  /// **'Create Ad'**
  String get createAd;

  /// No description provided for @activeCasesLimit.
  ///
  /// In en, this message translates to:
  /// **'Active Cases Limit'**
  String get activeCasesLimit;

  /// No description provided for @activeCasesInUse.
  ///
  /// In en, this message translates to:
  /// **'{count}/5 active cases are currently in use.'**
  String activeCasesInUse(Object count);

  /// No description provided for @adsPausedDueToLimit.
  ///
  /// In en, this message translates to:
  /// **'Your ads are paused because you reached the 5 active cases limit.'**
  String get adsPausedDueToLimit;

  /// No description provided for @totalAds.
  ///
  /// In en, this message translates to:
  /// **'Total Ads'**
  String get totalAds;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @yourAds.
  ///
  /// In en, this message translates to:
  /// **'Your Ads'**
  String get yourAds;

  /// No description provided for @editDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit Details'**
  String get editDetails;

  /// No description provided for @activateAd.
  ///
  /// In en, this message translates to:
  /// **'Activate Ad'**
  String get activateAd;

  /// No description provided for @deleteAdConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{title}\"? This action cannot be undone.'**
  String deleteAdConfirm(Object title);

  /// No description provided for @cannotReactivateAd.
  ///
  /// In en, this message translates to:
  /// **'Cannot Reactivate Ad'**
  String get cannotReactivateAd;

  /// No description provided for @cannotReactivateAdMessage.
  ///
  /// In en, this message translates to:
  /// **'You have reached the maximum of 5 active cases. Complete or close some cases before reactivating ads.'**
  String get cannotReactivateAdMessage;

  /// No description provided for @refineResults.
  ///
  /// In en, this message translates to:
  /// **'Refine Results'**
  String get refineResults;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get sortBy;

  /// No description provided for @newest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get newest;

  /// No description provided for @budgetHighToLow.
  ///
  /// In en, this message translates to:
  /// **'Budget: High to Low'**
  String get budgetHighToLow;

  /// No description provided for @budgetLowToHigh.
  ///
  /// In en, this message translates to:
  /// **'Budget: Low to High'**
  String get budgetLowToHigh;

  /// No description provided for @jobType.
  ///
  /// In en, this message translates to:
  /// **'Job Type'**
  String get jobType;

  /// No description provided for @corporate.
  ///
  /// In en, this message translates to:
  /// **'Corporate'**
  String get corporate;

  /// No description provided for @criminal.
  ///
  /// In en, this message translates to:
  /// **'Criminal'**
  String get criminal;

  /// No description provided for @civil.
  ///
  /// In en, this message translates to:
  /// **'Civil'**
  String get civil;

  /// No description provided for @property.
  ///
  /// In en, this message translates to:
  /// **'Property'**
  String get property;

  /// No description provided for @family.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get family;

  /// No description provided for @budgetRangePkr.
  ///
  /// In en, this message translates to:
  /// **'Budget Range (PKR)'**
  String get budgetRangePkr;

  /// No description provided for @zeroK.
  ///
  /// In en, this message translates to:
  /// **'0k'**
  String get zeroK;

  /// No description provided for @thousandKPlus.
  ///
  /// In en, this message translates to:
  /// **'1000k+'**
  String get thousandKPlus;

  /// No description provided for @showResults.
  ///
  /// In en, this message translates to:
  /// **'Show Results'**
  String get showResults;

  /// No description provided for @findWork.
  ///
  /// In en, this message translates to:
  /// **'Find Work'**
  String get findWork;

  /// No description provided for @searchJobs.
  ///
  /// In en, this message translates to:
  /// **'Search jobs...'**
  String get searchJobs;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @noJobsFound.
  ///
  /// In en, this message translates to:
  /// **'No jobs found'**
  String get noJobsFound;

  /// No description provided for @pleaseLoginToSubmitProposal.
  ///
  /// In en, this message translates to:
  /// **'Please login to submit a proposal'**
  String get pleaseLoginToSubmitProposal;

  /// No description provided for @pleaseFillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all fields'**
  String get pleaseFillAllFields;

  /// No description provided for @lawyer.
  ///
  /// In en, this message translates to:
  /// **'Lawyer'**
  String get lawyer;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @proposalSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Proposal submitted successfully!'**
  String get proposalSubmittedSuccessfully;

  /// No description provided for @jobDetails.
  ///
  /// In en, this message translates to:
  /// **'Job Details'**
  String get jobDetails;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @proposals.
  ///
  /// In en, this message translates to:
  /// **'Proposals'**
  String get proposals;

  /// No description provided for @jobDescription.
  ///
  /// In en, this message translates to:
  /// **'Job Description'**
  String get jobDescription;

  /// No description provided for @attachments.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get attachments;

  /// No description provided for @aboutTheClient.
  ///
  /// In en, this message translates to:
  /// **'About the Client'**
  String get aboutTheClient;

  /// No description provided for @joined.
  ///
  /// In en, this message translates to:
  /// **'Joined {date}'**
  String joined(Object date);

  /// No description provided for @memberSince2024.
  ///
  /// In en, this message translates to:
  /// **'Member since 2024'**
  String get memberSince2024;

  /// No description provided for @proposalSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Proposal Submitted'**
  String get proposalSubmitted;

  /// No description provided for @proposalAlreadySubmitted.
  ///
  /// In en, this message translates to:
  /// **'You have already submitted a proposal for this job. You can edit it below.'**
  String get proposalAlreadySubmitted;

  /// No description provided for @submitAProposal.
  ///
  /// In en, this message translates to:
  /// **'Submit a Proposal'**
  String get submitAProposal;

  /// No description provided for @bidAmountPkr.
  ///
  /// In en, this message translates to:
  /// **'Bid Amount (PKR)'**
  String get bidAmountPkr;

  /// No description provided for @example50000.
  ///
  /// In en, this message translates to:
  /// **'e.g. 50000'**
  String get example50000;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @example7Days.
  ///
  /// In en, this message translates to:
  /// **'e.g. 7 Days'**
  String get example7Days;

  /// No description provided for @coverLetter.
  ///
  /// In en, this message translates to:
  /// **'Cover Letter'**
  String get coverLetter;

  /// No description provided for @describeWhyYouAreBestFit.
  ///
  /// In en, this message translates to:
  /// **'Describe why you are the best fit for this job...'**
  String get describeWhyYouAreBestFit;

  /// No description provided for @submitProposal.
  ///
  /// In en, this message translates to:
  /// **'Submit Proposal'**
  String get submitProposal;

  /// No description provided for @noProposalsYet.
  ///
  /// In en, this message translates to:
  /// **'No proposals yet'**
  String get noProposalsYet;

  /// No description provided for @beTheFirstToSubmit.
  ///
  /// In en, this message translates to:
  /// **'Be the first to submit a proposal!'**
  String get beTheFirstToSubmit;

  /// No description provided for @deleteProposal.
  ///
  /// In en, this message translates to:
  /// **'Delete Proposal?'**
  String get deleteProposal;

  /// No description provided for @deleteProposalConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this proposal? This action cannot be undone.'**
  String get deleteProposalConfirm;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @proposalDeleted.
  ///
  /// In en, this message translates to:
  /// **'Proposal deleted'**
  String get proposalDeleted;

  /// No description provided for @editProposal.
  ///
  /// In en, this message translates to:
  /// **'Edit Proposal'**
  String get editProposal;

  /// No description provided for @bidAmount.
  ///
  /// In en, this message translates to:
  /// **'Bid Amount'**
  String get bidAmount;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @proposalUpdated.
  ///
  /// In en, this message translates to:
  /// **'Proposal updated'**
  String get proposalUpdated;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @pleaseLoginToManageAds.
  ///
  /// In en, this message translates to:
  /// **'Please login to manage ads'**
  String get pleaseLoginToManageAds;

  /// No description provided for @manageAds.
  ///
  /// In en, this message translates to:
  /// **'Manage Ads'**
  String get manageAds;

  /// No description provided for @newAd.
  ///
  /// In en, this message translates to:
  /// **'New Ad'**
  String get newAd;

  /// No description provided for @errorLoadingAds.
  ///
  /// In en, this message translates to:
  /// **'Error loading ads'**
  String get errorLoadingAds;

  /// No description provided for @noAdsYet.
  ///
  /// In en, this message translates to:
  /// **'No Ads Yet'**
  String get noAdsYet;

  /// No description provided for @createYourFirstAdToAttractClients.
  ///
  /// In en, this message translates to:
  /// **'Create your first ad to attract clients.'**
  String get createYourFirstAdToAttractClients;

  /// No description provided for @postACase.
  ///
  /// In en, this message translates to:
  /// **'Post a Case'**
  String get postACase;

  /// No description provided for @caseDetails.
  ///
  /// In en, this message translates to:
  /// **'Case Details'**
  String get caseDetails;

  /// No description provided for @caseTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Case Title'**
  String get caseTitleLabel;

  /// No description provided for @caseTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Enter case title'**
  String get caseTitleHint;

  /// No description provided for @pleaseEnterCaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter case title'**
  String get pleaseEnterCaseTitle;

  /// No description provided for @titleMinLength.
  ///
  /// In en, this message translates to:
  /// **'Title must be at least {min} characters'**
  String titleMinLength(Object min);

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @pleaseSelectCategory.
  ///
  /// In en, this message translates to:
  /// **'Please select a category'**
  String get pleaseSelectCategory;

  /// No description provided for @cityLabel.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get cityLabel;

  /// No description provided for @cityHint.
  ///
  /// In en, this message translates to:
  /// **'Enter city'**
  String get cityHint;

  /// No description provided for @pleaseEnterCity.
  ///
  /// In en, this message translates to:
  /// **'Please enter city'**
  String get pleaseEnterCity;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the case'**
  String get descriptionHint;

  /// No description provided for @pleaseDescribeCase.
  ///
  /// In en, this message translates to:
  /// **'Please describe the case'**
  String get pleaseDescribeCase;

  /// No description provided for @descriptionMinLength.
  ///
  /// In en, this message translates to:
  /// **'Description must be at least {min} characters'**
  String descriptionMinLength(Object min);

  /// No description provided for @tapToUploadDocuments.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload documents'**
  String get tapToUploadDocuments;

  /// No description provided for @pdfWordImages.
  ///
  /// In en, this message translates to:
  /// **'PDF, Word, images'**
  String get pdfWordImages;

  /// No description provided for @postingCase.
  ///
  /// In en, this message translates to:
  /// **'Posting case...'**
  String get postingCase;

  /// No description provided for @noLawyerAssignedYet.
  ///
  /// In en, this message translates to:
  /// **'No lawyer assigned yet'**
  String get noLawyerAssignedYet;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @caseDescription.
  ///
  /// In en, this message translates to:
  /// **'Case Description'**
  String get caseDescription;

  /// No description provided for @legalJourney.
  ///
  /// In en, this message translates to:
  /// **'The Legal Journey'**
  String get legalJourney;

  /// No description provided for @dashboardRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Dashboard refreshed'**
  String get dashboardRefreshed;

  /// No description provided for @welcomeBackComma.
  ///
  /// In en, this message translates to:
  /// **'Welcome back,'**
  String get welcomeBackComma;

  /// No description provided for @todaysAgenda.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Agenda'**
  String get todaysAgenda;

  /// No description provided for @allCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'All caught up!'**
  String get allCaughtUp;

  /// No description provided for @noUrgentEventsToday.
  ///
  /// In en, this message translates to:
  /// **'No urgent events or hearings today. Take your day seriously.'**
  String get noUrgentEventsToday;

  /// No description provided for @consultationEvent.
  ///
  /// In en, this message translates to:
  /// **'Consultation'**
  String get consultationEvent;

  /// No description provided for @hearingEvent.
  ///
  /// In en, this message translates to:
  /// **'Hearing'**
  String get hearingEvent;

  /// No description provided for @workspaceEvent.
  ///
  /// In en, this message translates to:
  /// **'Workspace Event'**
  String get workspaceEvent;

  /// No description provided for @openWorkspaceEvent.
  ///
  /// In en, this message translates to:
  /// **'Open Workspace Event'**
  String get openWorkspaceEvent;

  /// No description provided for @noActiveCasesYetApplyToJobs.
  ///
  /// In en, this message translates to:
  /// **'No active cases yet.\nApply to jobs to find work!'**
  String get noActiveCasesYetApplyToJobs;

  /// No description provided for @openWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Open Workspace'**
  String get openWorkspace;

  /// No description provided for @noScheduledConsultations.
  ///
  /// In en, this message translates to:
  /// **'No scheduled consultations'**
  String get noScheduledConsultations;

  /// No description provided for @videoCall.
  ///
  /// In en, this message translates to:
  /// **'Video Call'**
  String get videoCall;

  /// No description provided for @inPerson.
  ///
  /// In en, this message translates to:
  /// **'In-Person'**
  String get inPerson;

  /// No description provided for @clientLabel.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get clientLabel;

  /// No description provided for @idLabel.
  ///
  /// In en, this message translates to:
  /// **'ID:'**
  String get idLabel;

  /// No description provided for @budgetRange.
  ///
  /// In en, this message translates to:
  /// **'Budget: {min} - {max}'**
  String budgetRange(Object max, Object min);

  /// No description provided for @withLabel.
  ///
  /// In en, this message translates to:
  /// **'With: {name}'**
  String withLabel(Object name);

  /// No description provided for @timeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time: {time}'**
  String timeLabel(Object time);

  /// No description provided for @respond.
  ///
  /// In en, this message translates to:
  /// **'Respond'**
  String get respond;

  /// No description provided for @goToWorkspaceToRespondToConsultation.
  ///
  /// In en, this message translates to:
  /// **'Go to workspace to respond to consultation'**
  String get goToWorkspaceToRespondToConsultation;

  /// No description provided for @cancelConsultation.
  ///
  /// In en, this message translates to:
  /// **'Cancel Consultation'**
  String get cancelConsultation;

  /// No description provided for @areYouSureWantToCancelConsultation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this consultation?'**
  String get areYouSureWantToCancelConsultation;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @consultationCancelled.
  ///
  /// In en, this message translates to:
  /// **'Consultation cancelled'**
  String get consultationCancelled;

  /// No description provided for @cancelledByLawyer.
  ///
  /// In en, this message translates to:
  /// **'Cancelled by lawyer'**
  String get cancelledByLawyer;

  /// No description provided for @acceptedStatus.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get acceptedStatus;

  /// No description provided for @pendingStatus.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingStatus;

  /// No description provided for @rejectedStatus.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejectedStatus;

  /// No description provided for @cancelledStatus.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelledStatus;

  /// No description provided for @completedStatus.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedStatus;

  /// No description provided for @noShowStatus.
  ///
  /// In en, this message translates to:
  /// **'No Show'**
  String get noShowStatus;

  /// No description provided for @activeCases.
  ///
  /// In en, this message translates to:
  /// **'Active Cases'**
  String get activeCases;

  /// No description provided for @noActiveCases.
  ///
  /// In en, this message translates to:
  /// **'No active cases'**
  String get noActiveCases;

  /// No description provided for @postNewCaseToGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Post a new case to get started.'**
  String get postNewCaseToGetStarted;

  /// No description provided for @untitledCase.
  ///
  /// In en, this message translates to:
  /// **'Untitled Case'**
  String get untitledCase;

  /// No description provided for @recentUpdates.
  ///
  /// In en, this message translates to:
  /// **'Recent Updates'**
  String get recentUpdates;

  /// No description provided for @noRecentUpdatesYet.
  ///
  /// In en, this message translates to:
  /// **'No recent updates yet'**
  String get noRecentUpdatesYet;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @availabilitySettings.
  ///
  /// In en, this message translates to:
  /// **'Availability Settings'**
  String get availabilitySettings;

  /// No description provided for @walletBalance.
  ///
  /// In en, this message translates to:
  /// **'Wallet Balance'**
  String get walletBalance;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @postAd.
  ///
  /// In en, this message translates to:
  /// **'Post Ad'**
  String get postAd;

  /// No description provided for @withdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdraw;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// No description provided for @myActiveAds.
  ///
  /// In en, this message translates to:
  /// **'My Active Ads'**
  String get myActiveAds;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @noActiveAdsYet.
  ///
  /// In en, this message translates to:
  /// **'No active ads yet'**
  String get noActiveAdsYet;

  /// No description provided for @newJobMatches.
  ///
  /// In en, this message translates to:
  /// **'New Job Matches'**
  String get newJobMatches;

  /// No description provided for @createFirstAdHint.
  ///
  /// In en, this message translates to:
  /// **'Create your first ad from quick actions to appear in client search.'**
  String get createFirstAdHint;

  /// No description provided for @explore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// No description provided for @noJobMatchesFound.
  ///
  /// In en, this message translates to:
  /// **'No job matches available right now.'**
  String get noJobMatchesFound;

  /// No description provided for @pauseAd.
  ///
  /// In en, this message translates to:
  /// **'Pause Ad'**
  String get pauseAd;

  /// No description provided for @resumeAd.
  ///
  /// In en, this message translates to:
  /// **'Resume Ad'**
  String get resumeAd;

  /// No description provided for @deleteAd.
  ///
  /// In en, this message translates to:
  /// **'Delete Ad'**
  String get deleteAd;

  /// No description provided for @uploadBothCnicAndSelfie.
  ///
  /// In en, this message translates to:
  /// **'Please upload both CNIC and selfie to proceed.'**
  String get uploadBothCnicAndSelfie;

  /// No description provided for @verifyIdentityTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Identity'**
  String get verifyIdentityTitle;

  /// No description provided for @identityVerification.
  ///
  /// In en, this message translates to:
  /// **'Identity Verification'**
  String get identityVerification;

  /// No description provided for @uploadCnicAndSelfie.
  ///
  /// In en, this message translates to:
  /// **'Please upload your CNIC and a selfie.'**
  String get uploadCnicAndSelfie;

  /// No description provided for @cnicFrontLabel.
  ///
  /// In en, this message translates to:
  /// **'CNIC (Front)'**
  String get cnicFrontLabel;

  /// No description provided for @yourSelfieLabel.
  ///
  /// In en, this message translates to:
  /// **'Your Selfie'**
  String get yourSelfieLabel;

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get uploading;

  /// No description provided for @submitVerification.
  ///
  /// In en, this message translates to:
  /// **'Submit Verification'**
  String get submitVerification;

  /// No description provided for @tapToUpload.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload {label}'**
  String tapToUpload(Object label);

  /// No description provided for @legalServices.
  ///
  /// In en, this message translates to:
  /// **'Legal Services'**
  String get legalServices;

  /// No description provided for @findLawyers.
  ///
  /// In en, this message translates to:
  /// **'Find Lawyers'**
  String get findLawyers;

  /// No description provided for @documentReview.
  ///
  /// In en, this message translates to:
  /// **'Document Review'**
  String get documentReview;

  /// No description provided for @legalArticles.
  ///
  /// In en, this message translates to:
  /// **'Legal Articles'**
  String get legalArticles;

  /// No description provided for @lawyerNotFound.
  ///
  /// In en, this message translates to:
  /// **'Lawyer not found'**
  String get lawyerNotFound;

  /// No description provided for @bookConsultation.
  ///
  /// In en, this message translates to:
  /// **'Book Consultation'**
  String get bookConsultation;

  /// No description provided for @lawyerFocus.
  ///
  /// In en, this message translates to:
  /// **'Lawyer Focus'**
  String get lawyerFocus;

  /// No description provided for @topicBriefDescription.
  ///
  /// In en, this message translates to:
  /// **'Topic / Brief Description'**
  String get topicBriefDescription;

  /// No description provided for @consultationHint.
  ///
  /// In en, this message translates to:
  /// **'What is this consultation about?'**
  String get consultationHint;

  /// No description provided for @meetingPreference.
  ///
  /// In en, this message translates to:
  /// **'Meeting Preference'**
  String get meetingPreference;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select Time'**
  String get selectTime;

  /// No description provided for @pleaseSelectDateFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select a date first'**
  String get pleaseSelectDateFirst;

  /// No description provided for @totalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalLabel;

  /// No description provided for @reviewAndPay.
  ///
  /// In en, this message translates to:
  /// **'Review & Pay'**
  String get reviewAndPay;

  /// No description provided for @currencyPKR.
  ///
  /// In en, this message translates to:
  /// **'PKR'**
  String get currencyPKR;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @verifiedLawyer.
  ///
  /// In en, this message translates to:
  /// **'Verified Lawyer'**
  String get verifiedLawyer;

  /// No description provided for @yearsExperience.
  ///
  /// In en, this message translates to:
  /// **'Years Exp'**
  String get yearsExperience;

  /// No description provided for @casesWon.
  ///
  /// In en, this message translates to:
  /// **'Cases Won'**
  String get casesWon;

  /// No description provided for @ratingLabel.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get ratingLabel;

  /// No description provided for @aboutMe.
  ///
  /// In en, this message translates to:
  /// **'About Me'**
  String get aboutMe;

  /// No description provided for @specializationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Specializations'**
  String get specializationsLabel;

  /// No description provided for @educationAndCredentials.
  ///
  /// In en, this message translates to:
  /// **'Education & Credentials'**
  String get educationAndCredentials;

  /// No description provided for @clientReviews.
  ///
  /// In en, this message translates to:
  /// **'Client Reviews'**
  String get clientReviews;

  /// No description provided for @reviewsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} reviews'**
  String reviewsCount(Object count);

  /// No description provided for @workplaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Work Place'**
  String get workplaceTitle;

  /// No description provided for @files.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get files;

  /// No description provided for @events.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get events;

  /// No description provided for @milestones.
  ///
  /// In en, this message translates to:
  /// **'Milestones'**
  String get milestones;

  /// No description provided for @invoices.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get invoices;

  /// No description provided for @partnerDetailsNotFound.
  ///
  /// In en, this message translates to:
  /// **'Partner details not found'**
  String get partnerDetailsNotFound;

  /// No description provided for @client.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get client;

  /// No description provided for @yearsExperienceShort.
  ///
  /// In en, this message translates to:
  /// **'yrs exp'**
  String get yearsExperienceShort;

  /// No description provided for @fundsInCustody.
  ///
  /// In en, this message translates to:
  /// **'Funds in Custody'**
  String get fundsInCustody;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @heldInSystemCustody.
  ///
  /// In en, this message translates to:
  /// **'Held in system custody'**
  String get heldInSystemCustody;

  /// No description provided for @heldAmount.
  ///
  /// In en, this message translates to:
  /// **'Held Amount'**
  String get heldAmount;

  /// No description provided for @caseSummary.
  ///
  /// In en, this message translates to:
  /// **'Case Summary'**
  String get caseSummary;

  /// No description provided for @projectDetails.
  ///
  /// In en, this message translates to:
  /// **'Project Details'**
  String get projectDetails;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @budget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budget;

  /// No description provided for @agreedWithLawyer.
  ///
  /// In en, this message translates to:
  /// **'Agreed with Lawyer'**
  String get agreedWithLawyer;

  /// No description provided for @clientRange.
  ///
  /// In en, this message translates to:
  /// **'Client Range'**
  String get clientRange;

  /// No description provided for @inPersonMeeting.
  ///
  /// In en, this message translates to:
  /// **'In-Person Meeting'**
  String get inPersonMeeting;

  /// No description provided for @virtualOnline.
  ///
  /// In en, this message translates to:
  /// **'Virtual / Online'**
  String get virtualOnline;

  /// No description provided for @timelineAndStatus.
  ///
  /// In en, this message translates to:
  /// **'Timeline & Status'**
  String get timelineAndStatus;

  /// No description provided for @createdOn.
  ///
  /// In en, this message translates to:
  /// **'Created On'**
  String get createdOn;

  /// No description provided for @caseCompletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Case Completed Successfully'**
  String get caseCompletedSuccessfully;

  /// No description provided for @waitingForClientToVerifyWork.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Client to verify work...'**
  String get waitingForClientToVerifyWork;

  /// No description provided for @workApprovedWaitingForPaymentRelease.
  ///
  /// In en, this message translates to:
  /// **'Work approved! Waiting for payment release...'**
  String get workApprovedWaitingForPaymentRelease;

  /// No description provided for @finishWorkSignalClient.
  ///
  /// In en, this message translates to:
  /// **'Have you finished the work? Send a signal to the client to verify and release payment.'**
  String get finishWorkSignalClient;

  /// No description provided for @signalWorkDone.
  ///
  /// In en, this message translates to:
  /// **'Signal Work Done'**
  String get signalWorkDone;

  /// No description provided for @lawyerMarkedWorkDoneVerify.
  ///
  /// In en, this message translates to:
  /// **'Lawyer has marked the work as done. Please verify if you are satisfied.'**
  String get lawyerMarkedWorkDoneVerify;

  /// No description provided for @stillPending.
  ///
  /// In en, this message translates to:
  /// **'Still Pending'**
  String get stillPending;

  /// No description provided for @workApproved.
  ///
  /// In en, this message translates to:
  /// **'Work Approved'**
  String get workApproved;

  /// No description provided for @workApprovedRateAndRelease.
  ///
  /// In en, this message translates to:
  /// **'Work approved! Please rate the lawyer and release the payment to close the case.'**
  String get workApprovedRateAndRelease;

  /// No description provided for @rateAndReleasePayment.
  ///
  /// In en, this message translates to:
  /// **'Rate & Release Payment'**
  String get rateAndReleasePayment;

  /// No description provided for @currentStatus.
  ///
  /// In en, this message translates to:
  /// **'Current Status'**
  String get currentStatus;

  /// No description provided for @currentlyActiveWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Currently Active (Workspace)'**
  String get currentlyActiveWorkspace;

  /// No description provided for @caseClosedCompleted.
  ///
  /// In en, this message translates to:
  /// **'Case Closed / Completed'**
  String get caseClosedCompleted;

  /// No description provided for @requestConsultation.
  ///
  /// In en, this message translates to:
  /// **'Request Consultation'**
  String get requestConsultation;

  /// No description provided for @noConsultationsScheduledYet.
  ///
  /// In en, this message translates to:
  /// **'No consultations scheduled yet.\nRequest one above!'**
  String get noConsultationsScheduledYet;

  /// No description provided for @partnerLabel.
  ///
  /// In en, this message translates to:
  /// **'Partner'**
  String get partnerLabel;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @uploadFile.
  ///
  /// In en, this message translates to:
  /// **'Upload File'**
  String get uploadFile;

  /// No description provided for @originalAttachment.
  ///
  /// In en, this message translates to:
  /// **'Original Attachment'**
  String get originalAttachment;

  /// No description provided for @noFilesSharedYet.
  ///
  /// In en, this message translates to:
  /// **'No files shared yet.\nUpload documents here!'**
  String get noFilesSharedYet;

  /// No description provided for @uploadedByClientInitial.
  ///
  /// In en, this message translates to:
  /// **'Uploaded by Client (Initial)'**
  String get uploadedByClientInitial;

  /// No description provided for @uploadedByClient.
  ///
  /// In en, this message translates to:
  /// **'Uploaded by Client'**
  String get uploadedByClient;

  /// No description provided for @uploadedByLawyer.
  ///
  /// In en, this message translates to:
  /// **'Uploaded by Lawyer'**
  String get uploadedByLawyer;

  /// No description provided for @addEvent.
  ///
  /// In en, this message translates to:
  /// **'Add Event'**
  String get addEvent;

  /// No description provided for @onlyLawyerCanAddEvents.
  ///
  /// In en, this message translates to:
  /// **'Only lawyer can add events. You can view all updates here.'**
  String get onlyLawyerCanAddEvents;

  /// No description provided for @noCaseEventsYet.
  ///
  /// In en, this message translates to:
  /// **'No case events yet.\nLawyer can add updates here.'**
  String get noCaseEventsYet;

  /// No description provided for @place.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get place;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @addMilestoneTask.
  ///
  /// In en, this message translates to:
  /// **'Add Milestone / Task'**
  String get addMilestoneTask;

  /// No description provided for @noMilestonesYet.
  ///
  /// In en, this message translates to:
  /// **'No milestones yet.\nAdd tasks to keep progress clear.'**
  String get noMilestonesYet;

  /// No description provided for @due.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get due;

  /// No description provided for @noDueDate.
  ///
  /// In en, this message translates to:
  /// **'No due date'**
  String get noDueDate;

  /// No description provided for @availableSlotsForDate.
  ///
  /// In en, this message translates to:
  /// **'Available slots for {date}'**
  String availableSlotsForDate(Object date);

  /// No description provided for @noAvailableSlotsMessage.
  ///
  /// In en, this message translates to:
  /// **'No available slots on this date. Try a different day or duration.'**
  String get noAvailableSlotsMessage;

  /// No description provided for @videoMeetingDetails.
  ///
  /// In en, this message translates to:
  /// **'Video Meeting Details'**
  String get videoMeetingDetails;

  /// No description provided for @meetingLinkHint.
  ///
  /// In en, this message translates to:
  /// **'Meeting link (Zoom, Google Meet, etc.)'**
  String get meetingLinkHint;

  /// No description provided for @meetingLocation.
  ///
  /// In en, this message translates to:
  /// **'Meeting Location'**
  String get meetingLocation;

  /// No description provided for @meetingLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Address or location details'**
  String get meetingLocationHint;

  /// No description provided for @additionalNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Additional Notes (Optional)'**
  String get additionalNotesOptional;

  /// No description provided for @additionalNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Any special instructions or requirements...'**
  String get additionalNotesHint;

  /// No description provided for @sendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send Request'**
  String get sendRequest;

  /// No description provided for @pleaseEnterConsultationTopic.
  ///
  /// In en, this message translates to:
  /// **'Please enter a consultation topic'**
  String get pleaseEnterConsultationTopic;

  /// No description provided for @lawyerNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Lawyer is not available at the selected time'**
  String get lawyerNotAvailable;

  /// No description provided for @timeSlotConflictMessage.
  ///
  /// In en, this message translates to:
  /// **'Another consultation is already booked for this time slot'**
  String get timeSlotConflictMessage;

  /// No description provided for @consultationRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Consultation request sent!'**
  String get consultationRequestSent;

  /// No description provided for @signalCompletionTitle.
  ///
  /// In en, this message translates to:
  /// **'Signal Completion?'**
  String get signalCompletionTitle;

  /// No description provided for @signalCompletionMessage.
  ///
  /// In en, this message translates to:
  /// **'Answering \"Yes\" will notify the client that the work is finished and ask them to verify it.'**
  String get signalCompletionMessage;

  /// No description provided for @completionSignalSentToClient.
  ///
  /// In en, this message translates to:
  /// **'Completion signal sent to client'**
  String get completionSignalSentToClient;

  /// No description provided for @approveWorkTitle.
  ///
  /// In en, this message translates to:
  /// **'Approve Work?'**
  String get approveWorkTitle;

  /// No description provided for @rejectCompletionTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject Completion?'**
  String get rejectCompletionTitle;

  /// No description provided for @approveWorkMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to approve this work? You will be asked to rate and pay next.'**
  String get approveWorkMessage;

  /// No description provided for @rejectCompletionMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure the work is not done? This will signal the lawyer to continue working.'**
  String get rejectCompletionMessage;

  /// No description provided for @yesApprove.
  ///
  /// In en, this message translates to:
  /// **'Yes, Approve'**
  String get yesApprove;

  /// No description provided for @yesWorkPending.
  ///
  /// In en, this message translates to:
  /// **'Yes, Work is Pending'**
  String get yesWorkPending;

  /// No description provided for @rejectionSentToLawyer.
  ///
  /// In en, this message translates to:
  /// **'Rejection sent to lawyer'**
  String get rejectionSentToLawyer;

  /// No description provided for @rateLawyerTitle.
  ///
  /// In en, this message translates to:
  /// **'Rate Lawyer'**
  String get rateLawyerTitle;

  /// No description provided for @writeReviewHint.
  ///
  /// In en, this message translates to:
  /// **'Write a review...'**
  String get writeReviewHint;

  /// No description provided for @submitReviewAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Submit Review & Continue'**
  String get submitReviewAndContinue;

  /// No description provided for @failedToSubmitReview.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit review'**
  String get failedToSubmitReview;

  /// No description provided for @releasePaymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Release Payment'**
  String get releasePaymentTitle;

  /// No description provided for @releasePaymentDescription.
  ///
  /// In en, this message translates to:
  /// **'The work is approved and reviewed. Now release the agreed payment to the lawyer.'**
  String get releasePaymentDescription;

  /// No description provided for @agreedAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Agreed Amount:'**
  String get agreedAmountLabel;

  /// No description provided for @releasePaymentAction.
  ///
  /// In en, this message translates to:
  /// **'Release Payment'**
  String get releasePaymentAction;

  /// No description provided for @paymentReleasedAndCaseCompleted.
  ///
  /// In en, this message translates to:
  /// **'Payment released! Case marked as completed.'**
  String get paymentReleasedAndCaseCompleted;

  /// No description provided for @paymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment failed'**
  String get paymentFailed;

  /// No description provided for @paymentAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Amount'**
  String get paymentAmountLabel;

  /// No description provided for @paymentReleasedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Payment released successfully'**
  String get paymentReleasedSuccessfully;

  /// No description provided for @releaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Release failed'**
  String get releaseFailed;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @release.
  ///
  /// In en, this message translates to:
  /// **'Release'**
  String get release;

  /// No description provided for @pay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get pay;

  /// No description provided for @createInvoice.
  ///
  /// In en, this message translates to:
  /// **'Create Invoice'**
  String get createInvoice;

  /// No description provided for @noInvoicesYet.
  ///
  /// In en, this message translates to:
  /// **'No invoices yet.\nLawyer can create payment requests here.'**
  String get noInvoicesYet;

  /// No description provided for @titleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleLabel;

  /// No description provided for @milestoneTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Draft petition and review'**
  String get milestoneTitleHint;

  /// No description provided for @detailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detailsLabel;

  /// No description provided for @optionalTaskNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Optional notes for this task'**
  String get optionalTaskNotesHint;

  /// No description provided for @paymentAmountPKRLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Amount (PKR)'**
  String get paymentAmountPKRLabel;

  /// No description provided for @optionalLeaveEmptyIfNoPaymentRequired.
  ///
  /// In en, this message translates to:
  /// **'Optional - leave empty if no payment required'**
  String get optionalLeaveEmptyIfNoPaymentRequired;

  /// No description provided for @setDueDateOptional.
  ///
  /// In en, this message translates to:
  /// **'Set Due Date (Optional)'**
  String get setDueDateOptional;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @taskTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Task title is required'**
  String get taskTitleRequired;

  /// No description provided for @newMilestoneAdded.
  ///
  /// In en, this message translates to:
  /// **'New milestone added'**
  String get newMilestoneAdded;

  /// No description provided for @milestoneAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Milestone added successfully'**
  String get milestoneAddedSuccessfully;

  /// No description provided for @milestoneMarkedCompleted.
  ///
  /// In en, this message translates to:
  /// **'Milestone marked as completed'**
  String get milestoneMarkedCompleted;

  /// No description provided for @milestoneReopened.
  ///
  /// In en, this message translates to:
  /// **'Milestone reopened'**
  String get milestoneReopened;

  /// No description provided for @invoiceTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Invoice Title'**
  String get invoiceTitleLabel;

  /// No description provided for @invoiceTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Filing fee - stage 1'**
  String get invoiceTitleHint;

  /// No description provided for @amountPKRLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount (PKR)'**
  String get amountPKRLabel;

  /// No description provided for @amountHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., 15000'**
  String get amountHint;

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesLabel;

  /// No description provided for @optionalPaymentDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'Optional payment details'**
  String get optionalPaymentDetailsHint;

  /// No description provided for @titleAndValidAmountRequired.
  ///
  /// In en, this message translates to:
  /// **'Title and a valid amount are required'**
  String get titleAndValidAmountRequired;

  /// No description provided for @newInvoiceCreated.
  ///
  /// In en, this message translates to:
  /// **'New invoice created'**
  String get newInvoiceCreated;

  /// No description provided for @invoiceSentToClient.
  ///
  /// In en, this message translates to:
  /// **'Invoice sent to client'**
  String get invoiceSentToClient;

  /// No description provided for @invoiceCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Invoice created successfully'**
  String get invoiceCreatedSuccessfully;

  /// No description provided for @onlyPayerCanMarkInvoicePaid.
  ///
  /// In en, this message translates to:
  /// **'Only payer can mark invoice paid'**
  String get onlyPayerCanMarkInvoicePaid;

  /// No description provided for @insufficientBalanceForInvoice.
  ///
  /// In en, this message translates to:
  /// **'Insufficient balance. Available: PKR {available}, Required: PKR {required}'**
  String insufficientBalanceForInvoice(Object available, Object required);

  /// No description provided for @invoiceReleased.
  ///
  /// In en, this message translates to:
  /// **'Invoice released'**
  String get invoiceReleased;

  /// No description provided for @invoiceHeld.
  ///
  /// In en, this message translates to:
  /// **'Invoice held'**
  String get invoiceHeld;

  /// No description provided for @invoiceReleasedToLawyer.
  ///
  /// In en, this message translates to:
  /// **'{title} has been released to the lawyer'**
  String invoiceReleasedToLawyer(Object title);

  /// No description provided for @invoiceHeldInEscrow.
  ///
  /// In en, this message translates to:
  /// **'{title} has been held in escrow'**
  String invoiceHeldInEscrow(Object title);

  /// No description provided for @invoiceReleasedByClient.
  ///
  /// In en, this message translates to:
  /// **'Invoice released by client'**
  String get invoiceReleasedByClient;

  /// No description provided for @invoicePaymentHeld.
  ///
  /// In en, this message translates to:
  /// **'Invoice payment held'**
  String get invoicePaymentHeld;

  /// No description provided for @invoiceReleasedByClientMessage.
  ///
  /// In en, this message translates to:
  /// **'{title} has been released by the client'**
  String invoiceReleasedByClientMessage(Object title);

  /// No description provided for @invoicePaymentHeldMessage.
  ///
  /// In en, this message translates to:
  /// **'{title} has been held in escrow by the client'**
  String invoicePaymentHeldMessage(Object title);

  /// No description provided for @invoiceReleaseCompleted.
  ///
  /// In en, this message translates to:
  /// **'{title} release completed'**
  String invoiceReleaseCompleted(Object title);

  /// No description provided for @invoicePaymentHeldInEscrow.
  ///
  /// In en, this message translates to:
  /// **'{title} payment held in escrow'**
  String invoicePaymentHeldInEscrow(Object title);

  /// No description provided for @invoiceMarkedReleasedInWorkspace.
  ///
  /// In en, this message translates to:
  /// **'{title} marked released in workspace'**
  String invoiceMarkedReleasedInWorkspace(Object title);

  /// No description provided for @invoiceHeldInWorkspace.
  ///
  /// In en, this message translates to:
  /// **'{title} held in workspace'**
  String invoiceHeldInWorkspace(Object title);

  /// No description provided for @invoiceUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Invoice updated successfully'**
  String get invoiceUpdatedSuccessfully;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @held.
  ///
  /// In en, this message translates to:
  /// **'Held'**
  String get held;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @qualityOfWork.
  ///
  /// In en, this message translates to:
  /// **'Quality of Work'**
  String get qualityOfWork;

  /// No description provided for @budgetAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Budget Adjustment'**
  String get budgetAdjustment;

  /// No description provided for @wayOfTalking.
  ///
  /// In en, this message translates to:
  /// **'Way of Talking'**
  String get wayOfTalking;

  /// No description provided for @promptness.
  ///
  /// In en, this message translates to:
  /// **'Promptness'**
  String get promptness;

  /// No description provided for @expertise.
  ///
  /// In en, this message translates to:
  /// **'Expertise'**
  String get expertise;

  /// No description provided for @onlyClientCanPayMilestone.
  ///
  /// In en, this message translates to:
  /// **'Only client can pay milestone'**
  String get onlyClientCanPayMilestone;

  /// No description provided for @milestoneAlreadyPaid.
  ///
  /// In en, this message translates to:
  /// **'This milestone is already paid'**
  String get milestoneAlreadyPaid;

  /// No description provided for @insufficientBalanceForMilestone.
  ///
  /// In en, this message translates to:
  /// **'Insufficient balance. Available: PKR {available}, Required: PKR {required}'**
  String insufficientBalanceForMilestone(Object available, Object required);

  /// No description provided for @milestonePaymentReason.
  ///
  /// In en, this message translates to:
  /// **'Milestone payment: {title}'**
  String milestonePaymentReason(Object title);

  /// No description provided for @milestonePaymentHeld.
  ///
  /// In en, this message translates to:
  /// **'Milestone payment held'**
  String get milestonePaymentHeld;

  /// No description provided for @milestonePaymentHeldMessage.
  ///
  /// In en, this message translates to:
  /// **'PKR {amount} held in escrow for \"{title}\"'**
  String milestonePaymentHeldMessage(Object amount, Object title);

  /// No description provided for @milestonePaymentAwaitingRelease.
  ///
  /// In en, this message translates to:
  /// **'Milestone payment awaiting release'**
  String get milestonePaymentAwaitingRelease;

  /// No description provided for @milestonePaymentAwaitingReleaseMessage.
  ///
  /// In en, this message translates to:
  /// **'PKR {amount} is held in escrow for \"{title}\"'**
  String milestonePaymentAwaitingReleaseMessage(Object amount, Object title);

  /// No description provided for @milestonePaymentHeldInEscrow.
  ///
  /// In en, this message translates to:
  /// **'Payment of PKR {amount} held in escrow'**
  String milestonePaymentHeldInEscrow(Object amount);

  /// No description provided for @paymentFailedWithDetails.
  ///
  /// In en, this message translates to:
  /// **'Payment failed: {details}'**
  String paymentFailedWithDetails(Object details);

  /// No description provided for @addCaseEvent.
  ///
  /// In en, this message translates to:
  /// **'Add Case Event'**
  String get addCaseEvent;

  /// No description provided for @eventNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Event Name'**
  String get eventNameLabel;

  /// No description provided for @eventNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Court Hearing'**
  String get eventNameHint;

  /// No description provided for @eventPlaceLabel.
  ///
  /// In en, this message translates to:
  /// **'Event Place'**
  String get eventPlaceLabel;

  /// No description provided for @eventPlaceHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., District Court Lahore'**
  String get eventPlaceHint;

  /// No description provided for @eventNameAndPlaceRequired.
  ///
  /// In en, this message translates to:
  /// **'Event name and place are required'**
  String get eventNameAndPlaceRequired;

  /// No description provided for @createEvent.
  ///
  /// In en, this message translates to:
  /// **'Create Event'**
  String get createEvent;

  /// No description provided for @cannotCreateEventForThisCase.
  ///
  /// In en, this message translates to:
  /// **'Cannot create event for this case'**
  String get cannotCreateEventForThisCase;

  /// No description provided for @caseEventMessage.
  ///
  /// In en, this message translates to:
  /// **'{eventName} at {place} on {time}'**
  String caseEventMessage(Object eventName, Object place, Object time);

  /// No description provided for @newCaseEventAdded.
  ///
  /// In en, this message translates to:
  /// **'New case event added'**
  String get newCaseEventAdded;

  /// No description provided for @eventCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Event created successfully'**
  String get eventCreatedSuccessfully;

  /// No description provided for @newEventScheduled.
  ///
  /// In en, this message translates to:
  /// **'New event scheduled'**
  String get newEventScheduled;

  /// No description provided for @eventAddedToCase.
  ///
  /// In en, this message translates to:
  /// **'Event added to case'**
  String get eventAddedToCase;

  /// No description provided for @eventAddedAndUsersNotified.
  ///
  /// In en, this message translates to:
  /// **'Event added and users notified'**
  String get eventAddedAndUsersNotified;

  /// No description provided for @uploadLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Upload limit reached (Max 3 files per party)'**
  String get uploadLimitReached;

  /// No description provided for @maxFilesPerParty.
  ///
  /// In en, this message translates to:
  /// **'Max 3 files per party'**
  String get maxFilesPerParty;

  /// No description provided for @fileUploadedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'File uploaded successfully!'**
  String get fileUploadedSuccessfully;

  /// No description provided for @errorUploadingFile.
  ///
  /// In en, this message translates to:
  /// **'Error uploading file'**
  String get errorUploadingFile;

  /// No description provided for @nameYourFile.
  ///
  /// In en, this message translates to:
  /// **'Name your file'**
  String get nameYourFile;

  /// No description provided for @fileNameLabel.
  ///
  /// In en, this message translates to:
  /// **'File Name'**
  String get fileNameLabel;

  /// No description provided for @fileNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter name for other party to see'**
  String get fileNameHint;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @renameFile.
  ///
  /// In en, this message translates to:
  /// **'Rename file'**
  String get renameFile;

  /// No description provided for @newNameLabel.
  ///
  /// In en, this message translates to:
  /// **'New Name'**
  String get newNameLabel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @fileRenamed.
  ///
  /// In en, this message translates to:
  /// **'File renamed'**
  String get fileRenamed;

  /// No description provided for @renameFailed.
  ///
  /// In en, this message translates to:
  /// **'Rename failed'**
  String get renameFailed;

  /// No description provided for @deleteFileTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete File?'**
  String get deleteFileTitle;

  /// No description provided for @deleteFileConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{fileName}\"? This action cannot be undone.'**
  String deleteFileConfirm(Object fileName);

  /// No description provided for @fileDeleted.
  ///
  /// In en, this message translates to:
  /// **'File deleted'**
  String get fileDeleted;

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed'**
  String get deleteFailed;

  /// No description provided for @couldNotOpenFile.
  ///
  /// In en, this message translates to:
  /// **'Could not open file. No application found to handle this link.'**
  String get couldNotOpenFile;

  /// No description provided for @errorOpeningFile.
  ///
  /// In en, this message translates to:
  /// **'Error opening file'**
  String get errorOpeningFile;

  /// No description provided for @noLawyerOfficeLocationSet.
  ///
  /// In en, this message translates to:
  /// **'No lawyer office location set. Please agree on location via chat.'**
  String get noLawyerOfficeLocationSet;

  /// No description provided for @selectedTimeAlreadyPassed.
  ///
  /// In en, this message translates to:
  /// **'Selected time has already passed. Please choose a future time.'**
  String get selectedTimeAlreadyPassed;

  /// No description provided for @pleaseSelectFutureConsultationDateTime.
  ///
  /// In en, this message translates to:
  /// **'Please select a future date and time for consultation.'**
  String get pleaseSelectFutureConsultationDateTime;

  /// No description provided for @selectedTimeOutsideLawyerAvailability.
  ///
  /// In en, this message translates to:
  /// **'Selected time is outside the lawyer\'s availability.'**
  String get selectedTimeOutsideLawyerAvailability;

  /// No description provided for @selectedTimeConflictsWithAnotherConsultation.
  ///
  /// In en, this message translates to:
  /// **'Selected time conflicts with another consultation.'**
  String get selectedTimeConflictsWithAnotherConsultation;

  /// No description provided for @consultationLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Consultation Limit Reached'**
  String get consultationLimitReached;

  /// No description provided for @consultationLimitReachedDescription.
  ///
  /// In en, this message translates to:
  /// **'Each workspace includes 3 free consultations. You have reached this limit. Please pay to schedule more.'**
  String get consultationLimitReachedDescription;

  /// No description provided for @paymentGatewayComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Payment gateway coming soon...'**
  String get paymentGatewayComingSoon;

  /// No description provided for @payForOneMore.
  ///
  /// In en, this message translates to:
  /// **'Pay for 1 More (\$10)'**
  String get payForOneMore;

  /// No description provided for @noUserLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'No user logged in'**
  String get noUserLoggedIn;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ur'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
