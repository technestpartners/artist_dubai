import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

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
    Locale('ar'),
    Locale('en'),
  ];

  /// The name of the application
  ///
  /// In en, this message translates to:
  /// **'Artist Dubai'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'VIP Art & Cultural Community Platform'**
  String get tagline;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language'**
  String get languageSubtitle;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettings;

  /// No description provided for @accountInformation.
  ///
  /// In en, this message translates to:
  /// **'Account Information'**
  String get accountInformation;

  /// No description provided for @accountInformationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your account settings and preferences'**
  String get accountInformationSubtitle;

  /// No description provided for @artistProfile.
  ///
  /// In en, this message translates to:
  /// **'Artist Profile'**
  String get artistProfile;

  /// No description provided for @artistProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your active artist profile details on Artist Dubai'**
  String get artistProfileSubtitle;

  /// No description provided for @artistProfileCreateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your artist profile to showcase your work'**
  String get artistProfileCreateSubtitle;

  /// No description provided for @accountActions.
  ///
  /// In en, this message translates to:
  /// **'Account Actions'**
  String get accountActions;

  /// No description provided for @accountActionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out or delete your account'**
  String get accountActionsSubtitle;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member Since'**
  String get memberSince;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @noEmailProvided.
  ///
  /// In en, this message translates to:
  /// **'No email provided'**
  String get noEmailProvided;

  /// No description provided for @recentlyJoined.
  ///
  /// In en, this message translates to:
  /// **'Recently Joined'**
  String get recentlyJoined;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @viewDirectory.
  ///
  /// In en, this message translates to:
  /// **'View Directory'**
  String get viewDirectory;

  /// No description provided for @createArtistProfile.
  ///
  /// In en, this message translates to:
  /// **'Create Artist Profile'**
  String get createArtistProfile;

  /// No description provided for @noArtistProfile.
  ///
  /// In en, this message translates to:
  /// **'No Artist Profile'**
  String get noArtistProfile;

  /// No description provided for @noArtistProfileBody.
  ///
  /// In en, this message translates to:
  /// **'Create your artist profile to be discoverable on the platform and showcase your portfolio.'**
  String get noArtistProfileBody;

  /// No description provided for @pleaseSignIn.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to manage your account settings.'**
  String get pleaseSignIn;

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePasswordTitle;

  /// No description provided for @changePasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your new password. Make sure it\'s secure and at least 6 characters long.'**
  String get changePasswordSubtitle;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @newPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter new password'**
  String get newPasswordHint;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @confirmNewPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPasswordHint;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @updatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get updatePassword;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @passwordUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully!'**
  String get passwordUpdatedSuccess;

  /// No description provided for @passwordUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update password. Please check backend connection.'**
  String get passwordUpdateFailed;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Are you absolutely sure?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. This will permanently delete your account and remove all your data from our servers. This includes:'**
  String get deleteAccountBody;

  /// No description provided for @deleteAccountItem1.
  ///
  /// In en, this message translates to:
  /// **'Your artist profile (if any)'**
  String get deleteAccountItem1;

  /// No description provided for @deleteAccountItem2.
  ///
  /// In en, this message translates to:
  /// **'All your artwork images'**
  String get deleteAccountItem2;

  /// No description provided for @deleteAccountItem3.
  ///
  /// In en, this message translates to:
  /// **'Your account information'**
  String get deleteAccountItem3;

  /// No description provided for @deleteAccountItem4.
  ///
  /// In en, this message translates to:
  /// **'All your activity and event history'**
  String get deleteAccountItem4;

  /// No description provided for @deleteAccountItem5.
  ///
  /// In en, this message translates to:
  /// **'Any saved preferences'**
  String get deleteAccountItem5;

  /// No description provided for @deleteAccountItem6.
  ///
  /// In en, this message translates to:
  /// **'Your liked artists and galleries'**
  String get deleteAccountItem6;

  /// No description provided for @yesDeleteMyAccount.
  ///
  /// In en, this message translates to:
  /// **'Yes, delete my account'**
  String get yesDeleteMyAccount;

  /// No description provided for @accountDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account deleted successfully.'**
  String get accountDeletedSuccess;

  /// No description provided for @deleteAccountNote.
  ///
  /// In en, this message translates to:
  /// **'Note: Account deletion permanently removes your account and all associated data.'**
  String get deleteAccountNote;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get somethingWentWrong;

  /// No description provided for @noInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection detected.'**
  String get noInternet;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'VIP Sign In'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Access world-class artists and talent across UAE'**
  String get loginSubtitle;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create VIP Account'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join Dubai\'s premier artist & cultural community'**
  String get registerSubtitle;

  /// No description provided for @communityPlatform.
  ///
  /// In en, this message translates to:
  /// **'Community Platform'**
  String get communityPlatform;

  /// No description provided for @hostedBy.
  ///
  /// In en, this message translates to:
  /// **'Hosted by Nizar Fahem'**
  String get hostedBy;

  /// No description provided for @aboutUs.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get aboutUs;

  /// No description provided for @artists.
  ///
  /// In en, this message translates to:
  /// **'Artists'**
  String get artists;

  /// No description provided for @government.
  ///
  /// In en, this message translates to:
  /// **'Government'**
  String get government;

  /// No description provided for @artistRegistration.
  ///
  /// In en, this message translates to:
  /// **'Artist Registration'**
  String get artistRegistration;

  /// No description provided for @eventsCompetition.
  ///
  /// In en, this message translates to:
  /// **'Events Competition'**
  String get eventsCompetition;

  /// No description provided for @galleriesArtCenter.
  ///
  /// In en, this message translates to:
  /// **'Galleries & Art Center'**
  String get galleriesArtCenter;

  /// No description provided for @eventsPhotos.
  ///
  /// In en, this message translates to:
  /// **'Events Photos'**
  String get eventsPhotos;

  /// No description provided for @galleryRegistration.
  ///
  /// In en, this message translates to:
  /// **'Art Venue Registration'**
  String get galleryRegistration;

  /// No description provided for @events.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get events;

  /// No description provided for @galleries.
  ///
  /// In en, this message translates to:
  /// **'Galleries'**
  String get galleries;

  /// No description provided for @featuredArtists.
  ///
  /// In en, this message translates to:
  /// **'Featured Artists'**
  String get featuredArtists;

  /// No description provided for @noArtistProfilesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No artist profiles available yet'**
  String get noArtistProfilesAvailable;

  /// No description provided for @noArtistsYet.
  ///
  /// In en, this message translates to:
  /// **'No Artists Yet'**
  String get noArtistsYet;

  /// No description provided for @beTheFirstToCreateArtistProfile.
  ///
  /// In en, this message translates to:
  /// **'Be the first to create an artist profile!'**
  String get beTheFirstToCreateArtistProfile;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select category'**
  String get selectCategory;

  /// No description provided for @governmentPortal.
  ///
  /// In en, this message translates to:
  /// **'Government Portal'**
  String get governmentPortal;

  /// No description provided for @governmentPortalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Partnership opportunities with Dubai\'s government entities'**
  String get governmentPortalSubtitle;

  /// No description provided for @openStatus.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openStatus;

  /// No description provided for @closedStatus.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closedStatus;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// No description provided for @directions.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get directions;

  /// No description provided for @loginToYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Login to Your Account'**
  String get loginToYourAccount;

  /// No description provided for @welcomeBackLogin.
  ///
  /// In en, this message translates to:
  /// **'Welcome back! Enter your credentials to access your account'**
  String get welcomeBackLogin;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @enterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterYourPassword;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAccount;

  /// No description provided for @signUpFree.
  ///
  /// In en, this message translates to:
  /// **'Sign Up Free'**
  String get signUpFree;

  /// No description provided for @viewProfile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get viewProfile;

  /// No description provided for @eventsTitle.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get eventsTitle;

  /// No description provided for @eventsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Curated art exhibitions, workshops & gallery openings in Dubai'**
  String get eventsSubtitle;

  /// No description provided for @tabAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get tabAll;

  /// No description provided for @tabUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get tabUpcoming;

  /// No description provided for @tabOngoing.
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get tabOngoing;

  /// No description provided for @tabPast.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get tabPast;

  /// No description provided for @searchEventsHint.
  ///
  /// In en, this message translates to:
  /// **'Search events by name, location...'**
  String get searchEventsHint;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get allCategories;

  /// No description provided for @noEventsFound.
  ///
  /// In en, this message translates to:
  /// **'No Events Found'**
  String get noEventsFound;

  /// No description provided for @noEventsDescription.
  ///
  /// In en, this message translates to:
  /// **'Check back soon for exciting upcoming art events'**
  String get noEventsDescription;

  /// No description provided for @registerArtEvent.
  ///
  /// In en, this message translates to:
  /// **'Register Art Event'**
  String get registerArtEvent;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @addToCalendar.
  ///
  /// In en, this message translates to:
  /// **'Add to Calendar'**
  String get addToCalendar;

  /// No description provided for @freeEntry.
  ///
  /// In en, this message translates to:
  /// **'Free Entry'**
  String get freeEntry;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @galleriesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Physical galleries and art spaces across Dubai'**
  String get galleriesSubtitle;

  /// No description provided for @loginRequired.
  ///
  /// In en, this message translates to:
  /// **'Login Required'**
  String get loginRequired;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get logIn;

  /// No description provided for @virtualTour.
  ///
  /// In en, this message translates to:
  /// **'Virtual Tour'**
  String get virtualTour;

  /// No description provided for @noGalleriesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No galleries available yet'**
  String get noGalleriesAvailable;

  /// No description provided for @aboutUsTitle.
  ///
  /// In en, this message translates to:
  /// **'ABOUT US'**
  String get aboutUsTitle;

  /// No description provided for @aboutUsDescription.
  ///
  /// In en, this message translates to:
  /// **'VIP Art & Cultural Community Platform connecting artists, galleries, and art enthusiasts across the UAE.'**
  String get aboutUsDescription;

  /// No description provided for @eventsCompetitionTitle.
  ///
  /// In en, this message translates to:
  /// **'Events Competition'**
  String get eventsCompetitionTitle;

  /// No description provided for @eventsCompetitionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Competitions, contests, and open calls for artists in UAE'**
  String get eventsCompetitionSubtitle;

  /// No description provided for @noCompetitionsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No competitions available yet'**
  String get noCompetitionsAvailable;

  /// No description provided for @eventsPhotosTitle.
  ///
  /// In en, this message translates to:
  /// **'Events Photos'**
  String get eventsPhotosTitle;

  /// No description provided for @eventsPhotosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'High-resolution photo coverage from art exhibitions and galas'**
  String get eventsPhotosSubtitle;

  /// No description provided for @noPhotosAvailable.
  ///
  /// In en, this message translates to:
  /// **'No event photos available yet'**
  String get noPhotosAvailable;

  /// No description provided for @registerAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Your Account'**
  String get registerAccountTitle;

  /// No description provided for @registerAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join Dubai\'s premier art & cultural community'**
  String get registerAccountSubtitle;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordLabel;

  /// No description provided for @enterConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get enterConfirmPassword;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  /// No description provided for @signInNow.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInNow;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @myFavorites.
  ///
  /// In en, this message translates to:
  /// **'My Favorites'**
  String get myFavorites;

  /// No description provided for @noFavoritesYet.
  ///
  /// In en, this message translates to:
  /// **'No favorites saved yet'**
  String get noFavoritesYet;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// No description provided for @enterFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enterFullName;

  /// No description provided for @acceptTermsPrefix.
  ///
  /// In en, this message translates to:
  /// **'I accept the '**
  String get acceptTermsPrefix;

  /// No description provided for @andWord.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get andWord;

  /// No description provided for @myFavoritesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your saved artist profiles, favorited events, and liked artworks'**
  String get myFavoritesSubtitle;

  /// No description provided for @artworks.
  ///
  /// In en, this message translates to:
  /// **'Artworks'**
  String get artworks;

  /// No description provided for @noFavoritedArtistsYet.
  ///
  /// In en, this message translates to:
  /// **'No favorited artist profiles yet.'**
  String get noFavoritedArtistsYet;

  /// No description provided for @exploreArtists.
  ///
  /// In en, this message translates to:
  /// **'Explore Artists'**
  String get exploreArtists;

  /// No description provided for @noFavoritedEventsYet.
  ///
  /// In en, this message translates to:
  /// **'No favorited events saved.'**
  String get noFavoritedEventsYet;

  /// No description provided for @exploreEvents.
  ///
  /// In en, this message translates to:
  /// **'Explore Events'**
  String get exploreEvents;

  /// No description provided for @noFavoritedArtworksYet.
  ///
  /// In en, this message translates to:
  /// **'No favorited artworks saved.'**
  String get noFavoritedArtworksYet;

  /// No description provided for @explorePortfolios.
  ///
  /// In en, this message translates to:
  /// **'Explore Portfolios'**
  String get explorePortfolios;

  /// No description provided for @activelyFrom.
  ///
  /// In en, this message translates to:
  /// **'Actively from'**
  String get activelyFrom;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'back to home'**
  String get backToHome;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @likes.
  ///
  /// In en, this message translates to:
  /// **'Likes'**
  String get likes;

  /// No description provided for @portfolio.
  ///
  /// In en, this message translates to:
  /// **'Portfolio'**
  String get portfolio;

  /// No description provided for @aboutThisEvent.
  ///
  /// In en, this message translates to:
  /// **'About this event'**
  String get aboutThisEvent;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @organizer.
  ///
  /// In en, this message translates to:
  /// **'Organizer'**
  String get organizer;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get addPhoto;

  /// No description provided for @noEventPhotosYet.
  ///
  /// In en, this message translates to:
  /// **'No event photos yet'**
  String get noEventPhotosYet;

  /// No description provided for @exploreCategories.
  ///
  /// In en, this message translates to:
  /// **'Explore Categories'**
  String get exploreCategories;

  /// No description provided for @exploreCategoriesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Discover artists across various art forms and styles'**
  String get exploreCategoriesSubtitle;

  /// No description provided for @loadingArtists.
  ///
  /// In en, this message translates to:
  /// **'Loading artists...'**
  String get loadingArtists;

  /// No description provided for @discoverArtistsCount.
  ///
  /// In en, this message translates to:
  /// **'Discover {count} talented artists in Dubai'**
  String discoverArtistsCount(int count);

  /// No description provided for @artistCardStats.
  ///
  /// In en, this message translates to:
  /// **'{likes} likes   {artworks} artworks'**
  String artistCardStats(int likes, int artworks);

  /// No description provided for @organizedBy.
  ///
  /// In en, this message translates to:
  /// **'Organized by '**
  String get organizedBy;

  /// No description provided for @categoryAll.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get categoryAll;

  /// No description provided for @categoryArtExhibition.
  ///
  /// In en, this message translates to:
  /// **'Art Exhibition'**
  String get categoryArtExhibition;

  /// No description provided for @categoryGalleryOpening.
  ///
  /// In en, this message translates to:
  /// **'Gallery Opening'**
  String get categoryGalleryOpening;

  /// No description provided for @categoryArtWorkshop.
  ///
  /// In en, this message translates to:
  /// **'Art Workshop'**
  String get categoryArtWorkshop;

  /// No description provided for @categoryArtistTalk.
  ///
  /// In en, this message translates to:
  /// **'Artist Talk'**
  String get categoryArtistTalk;

  /// No description provided for @categoryArtFair.
  ///
  /// In en, this message translates to:
  /// **'Art Fair'**
  String get categoryArtFair;

  /// No description provided for @categorySculptureInstallation.
  ///
  /// In en, this message translates to:
  /// **'Sculpture Installation'**
  String get categorySculptureInstallation;

  /// No description provided for @categoryPhotographyExhibition.
  ///
  /// In en, this message translates to:
  /// **'Photography Exhibition'**
  String get categoryPhotographyExhibition;

  /// No description provided for @categoryCulturalFestival.
  ///
  /// In en, this message translates to:
  /// **'Cultural Festival'**
  String get categoryCulturalFestival;

  /// No description provided for @categoryArtCompetition.
  ///
  /// In en, this message translates to:
  /// **'Art Competition'**
  String get categoryArtCompetition;

  /// No description provided for @categoryCommunityArtProject.
  ///
  /// In en, this message translates to:
  /// **'Community Art Project'**
  String get categoryCommunityArtProject;

  /// No description provided for @myEvents.
  ///
  /// In en, this message translates to:
  /// **'My Events'**
  String get myEvents;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsAndConditions;

  /// No description provided for @createArtistProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Artist Profile'**
  String get createArtistProfileTitle;

  /// No description provided for @editArtistProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Artist Profile'**
  String get editArtistProfileTitle;

  /// No description provided for @createYourArtistProfile.
  ///
  /// In en, this message translates to:
  /// **'Create Your Artist Profile'**
  String get createYourArtistProfile;

  /// No description provided for @editYourArtistProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Your Artist Profile'**
  String get editYourArtistProfile;

  /// No description provided for @createArtistSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join Dubai\'s Artist Community and Showcase Your Portfolio'**
  String get createArtistSubtitle;

  /// No description provided for @editArtistSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your artist profile and showcase your portfolio'**
  String get editArtistSubtitle;

  /// No description provided for @basicInformation.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInformation;

  /// No description provided for @uploadArtistPhotoOptional.
  ///
  /// In en, this message translates to:
  /// **'Upload Artist Photo (Optional)'**
  String get uploadArtistPhotoOptional;

  /// No description provided for @changeProfilePicture.
  ///
  /// In en, this message translates to:
  /// **'Change Profile Picture'**
  String get changeProfilePicture;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullNameLabel;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @phoneNumberOptional.
  ///
  /// In en, this message translates to:
  /// **'Phone Number (Optional)'**
  String get phoneNumberOptional;

  /// No description provided for @locationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationLabel;

  /// No description provided for @artistInformation.
  ///
  /// In en, this message translates to:
  /// **'Artist Information'**
  String get artistInformation;

  /// No description provided for @artCategory.
  ///
  /// In en, this message translates to:
  /// **'Art Category'**
  String get artCategory;

  /// No description provided for @selectPrimaryArtForm.
  ///
  /// In en, this message translates to:
  /// **'Select your primary art form'**
  String get selectPrimaryArtForm;

  /// No description provided for @experienceLevel.
  ///
  /// In en, this message translates to:
  /// **'Experience Level'**
  String get experienceLevel;

  /// No description provided for @selectExperienceLevel.
  ///
  /// In en, this message translates to:
  /// **'Select your experience level'**
  String get selectExperienceLevel;

  /// No description provided for @artistBio.
  ///
  /// In en, this message translates to:
  /// **'Artist Bio'**
  String get artistBio;

  /// No description provided for @bioHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us about your artistic journey, style, and inspiration...'**
  String get bioHint;

  /// No description provided for @socialMediaOptional.
  ///
  /// In en, this message translates to:
  /// **'Social Media (Optional)'**
  String get socialMediaOptional;

  /// No description provided for @artworkPortfolio.
  ///
  /// In en, this message translates to:
  /// **'Artwork Portfolio'**
  String get artworkPortfolio;

  /// No description provided for @artworkPortfolioDesc.
  ///
  /// In en, this message translates to:
  /// **'Upload your artwork images (Max 6). You can crop, remove backgrounds, and manage your portfolio.'**
  String get artworkPortfolioDesc;

  /// No description provided for @dragDropImages.
  ///
  /// In en, this message translates to:
  /// **'Drag & drop images here or click to select'**
  String get dragDropImages;

  /// No description provided for @chooseFiles.
  ///
  /// In en, this message translates to:
  /// **'Choose Files'**
  String get chooseFiles;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @maxUploadsLimit.
  ///
  /// In en, this message translates to:
  /// **'Max 6 uploads • Max 5MB per file'**
  String get maxUploadsLimit;

  /// No description provided for @maxArtworksReached.
  ///
  /// In en, this message translates to:
  /// **'Maximum 6 artworks reached'**
  String get maxArtworksReached;

  /// No description provided for @markAsFeaturedArtwork.
  ///
  /// In en, this message translates to:
  /// **'Mark as Featured Artwork'**
  String get markAsFeaturedArtwork;

  /// No description provided for @agreeToTermsPrefix.
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get agreeToTermsPrefix;

  /// No description provided for @consentPrivacyTermsDesc.
  ///
  /// In en, this message translates to:
  /// **'By checking this box, you consent to the collection, processing, and storage of your personal data as described in our privacy policy. This includes your profile information, artwork images, and contact details which will be used to showcase your work on the Dubai Artist platform.'**
  String get consentPrivacyTermsDesc;

  /// No description provided for @createProfile.
  ///
  /// In en, this message translates to:
  /// **'Create Profile'**
  String get createProfile;

  /// No description provided for @updateProfile.
  ///
  /// In en, this message translates to:
  /// **'Update Profile'**
  String get updateProfile;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @creating.
  ///
  /// In en, this message translates to:
  /// **'Creating...'**
  String get creating;

  /// No description provided for @artVenue.
  ///
  /// In en, this message translates to:
  /// **'ART VENUE'**
  String get artVenue;

  /// No description provided for @artVenueSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Register your art venue or gallery to be listed in the app'**
  String get artVenueSubtitle;

  /// No description provided for @galleryCenterName.
  ///
  /// In en, this message translates to:
  /// **'Gallery / center name'**
  String get galleryCenterName;

  /// No description provided for @venueType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get venueType;

  /// No description provided for @venueTypeHint.
  ///
  /// In en, this message translates to:
  /// **'Gallery · Exhibition space · Studio'**
  String get venueTypeHint;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @contactPerson.
  ///
  /// In en, this message translates to:
  /// **'Contact person'**
  String get contactPerson;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @aboutTheSpace.
  ///
  /// In en, this message translates to:
  /// **'About the space'**
  String get aboutTheSpace;

  /// No description provided for @gallerySpacePhotoOptional.
  ///
  /// In en, this message translates to:
  /// **'Gallery / Space Photo (Optional)'**
  String get gallerySpacePhotoOptional;

  /// No description provided for @registerVenue.
  ///
  /// In en, this message translates to:
  /// **'Register Venue'**
  String get registerVenue;

  /// No description provided for @uploadingImage.
  ///
  /// In en, this message translates to:
  /// **'Uploading image to server...'**
  String get uploadingImage;

  /// No description provided for @myCreatedEvents.
  ///
  /// In en, this message translates to:
  /// **'MY CREATED EVENTS'**
  String get myCreatedEvents;

  /// No description provided for @myCreatedEventsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your published art events and community exhibitions'**
  String get myCreatedEventsSubtitle;

  /// No description provided for @createEvent.
  ///
  /// In en, this message translates to:
  /// **'Create Event'**
  String get createEvent;

  /// No description provided for @eventsCreated.
  ///
  /// In en, this message translates to:
  /// **'Events Created'**
  String get eventsCreated;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @totalCapacity.
  ///
  /// In en, this message translates to:
  /// **'Total Capacity'**
  String get totalCapacity;

  /// No description provided for @searchCreatedEvents.
  ///
  /// In en, this message translates to:
  /// **'Search your created events...'**
  String get searchCreatedEvents;

  /// No description provided for @noCreatedEventsYet.
  ///
  /// In en, this message translates to:
  /// **'No created events yet'**
  String get noCreatedEventsYet;

  /// No description provided for @createFirstEventPrompt.
  ///
  /// In en, this message translates to:
  /// **'Publish your first art event to manage tickets and view attendees here.'**
  String get createFirstEventPrompt;

  /// No description provided for @editCalendarEvent.
  ///
  /// In en, this message translates to:
  /// **'Edit Calendar Event'**
  String get editCalendarEvent;

  /// No description provided for @editEvent.
  ///
  /// In en, this message translates to:
  /// **'Edit Event'**
  String get editEvent;

  /// No description provided for @scheduleCalendarEvent.
  ///
  /// In en, this message translates to:
  /// **'Schedule on Calendar'**
  String get scheduleCalendarEvent;

  /// No description provided for @headerScheduleCalendarEvent.
  ///
  /// In en, this message translates to:
  /// **'SCHEDULE CALENDAR EVENT'**
  String get headerScheduleCalendarEvent;

  /// No description provided for @headerEditCalendarEvent.
  ///
  /// In en, this message translates to:
  /// **'EDIT CALENDAR EVENT'**
  String get headerEditCalendarEvent;

  /// No description provided for @headerCreateArtEvent.
  ///
  /// In en, this message translates to:
  /// **'CREATE ART EVENT'**
  String get headerCreateArtEvent;

  /// No description provided for @headerEditArtEvent.
  ///
  /// In en, this message translates to:
  /// **'EDIT ART EVENT'**
  String get headerEditArtEvent;

  /// No description provided for @headerSubtitleCalendarEdit.
  ///
  /// In en, this message translates to:
  /// **'Update scheduled exhibition or calendar date.'**
  String get headerSubtitleCalendarEdit;

  /// No description provided for @headerSubtitleCalendarCreate.
  ///
  /// In en, this message translates to:
  /// **'Schedule an upcoming exhibition, showcase, or cultural date on the calendar.'**
  String get headerSubtitleCalendarCreate;

  /// No description provided for @headerSubtitleEventEdit.
  ///
  /// In en, this message translates to:
  /// **'Update details, tickets, and photos for this event.'**
  String get headerSubtitleEventEdit;

  /// No description provided for @headerSubtitleEventCreate.
  ///
  /// In en, this message translates to:
  /// **'Publish a new exhibition, workshop, or cultural gathering.'**
  String get headerSubtitleEventCreate;

  /// No description provided for @featuredImage.
  ///
  /// In en, this message translates to:
  /// **'Featured Image'**
  String get featuredImage;

  /// No description provided for @changeImage.
  ///
  /// In en, this message translates to:
  /// **'Change Image'**
  String get changeImage;

  /// No description provided for @uploaded.
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get uploaded;

  /// No description provided for @uploadImagePrompt.
  ///
  /// In en, this message translates to:
  /// **'Select banner from device gallery or take a photo (JPG, PNG, WebP).'**
  String get uploadImagePrompt;

  /// No description provided for @eventInformation.
  ///
  /// In en, this message translates to:
  /// **'Event Information'**
  String get eventInformation;

  /// No description provided for @eventTitle.
  ///
  /// In en, this message translates to:
  /// **'Event Title'**
  String get eventTitle;

  /// No description provided for @enterEventTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter event title'**
  String get enterEventTitle;

  /// No description provided for @describeYourEvent.
  ///
  /// In en, this message translates to:
  /// **'Describe your event..'**
  String get describeYourEvent;

  /// No description provided for @dateTime.
  ///
  /// In en, this message translates to:
  /// **'Date & Time'**
  String get dateTime;

  /// No description provided for @startDateTime.
  ///
  /// In en, this message translates to:
  /// **'Start Date & Time'**
  String get startDateTime;

  /// No description provided for @endDateTimeOptional.
  ///
  /// In en, this message translates to:
  /// **'End Date & Time (Optional)'**
  String get endDateTimeOptional;

  /// No description provided for @venueNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Venue Name (Optional)'**
  String get venueNameOptional;

  /// No description provided for @venueNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Dubai Opera'**
  String get venueNameHint;

  /// No description provided for @addressLocation.
  ///
  /// In en, this message translates to:
  /// **'Address/Location'**
  String get addressLocation;

  /// No description provided for @searchLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Search or select location (e.g. Dubai, UAE)'**
  String get searchLocationHint;

  /// No description provided for @additionalDetails.
  ///
  /// In en, this message translates to:
  /// **'Additional Details'**
  String get additionalDetails;

  /// No description provided for @phoneOptional.
  ///
  /// In en, this message translates to:
  /// **'Phone Number (Optional)'**
  String get phoneOptional;

  /// No description provided for @requirementsOptional.
  ///
  /// In en, this message translates to:
  /// **'Requirements (Optional)'**
  String get requirementsOptional;

  /// No description provided for @requirementsHint.
  ///
  /// In en, this message translates to:
  /// **'Any special requirements or instructions for attendees..'**
  String get requirementsHint;

  /// No description provided for @tagsOptional.
  ///
  /// In en, this message translates to:
  /// **'Tags (Optional)'**
  String get tagsOptional;

  /// No description provided for @tagsHint.
  ///
  /// In en, this message translates to:
  /// **'Add tags (press Enter to add)'**
  String get tagsHint;

  /// No description provided for @paidPublishing.
  ///
  /// In en, this message translates to:
  /// **'PAID PUBLISHING'**
  String get paidPublishing;

  /// No description provided for @choosePublishingPlan.
  ///
  /// In en, this message translates to:
  /// **'Choose Publishing Plan'**
  String get choosePublishingPlan;

  /// No description provided for @paidPublishingDesc.
  ///
  /// In en, this message translates to:
  /// **'Publishing events is a paid service on Artist Dubai. Select your preferred promotion duration. Once reviewed and approved by the admin, your event will be broadcasted to art enthusiasts across Dubai.'**
  String get paidPublishingDesc;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @sixMonths.
  ///
  /// In en, this message translates to:
  /// **'6 Months'**
  String get sixMonths;

  /// No description provided for @daysActive7.
  ///
  /// In en, this message translates to:
  /// **'7 days active'**
  String get daysActive7;

  /// No description provided for @daysActive30.
  ///
  /// In en, this message translates to:
  /// **'30 days active'**
  String get daysActive30;

  /// No description provided for @daysActive180.
  ///
  /// In en, this message translates to:
  /// **'180 days active'**
  String get daysActive180;

  /// No description provided for @daysActive365.
  ///
  /// In en, this message translates to:
  /// **'365 days active'**
  String get daysActive365;

  /// No description provided for @save17Tag.
  ///
  /// In en, this message translates to:
  /// **'SAVE 17%'**
  String get save17Tag;

  /// No description provided for @save15Tag.
  ///
  /// In en, this message translates to:
  /// **'SAVE 15%'**
  String get save15Tag;

  /// No description provided for @popularTag.
  ///
  /// In en, this message translates to:
  /// **'POPULAR'**
  String get popularTag;

  /// No description provided for @bestValueTag.
  ///
  /// In en, this message translates to:
  /// **'BEST VALUE'**
  String get bestValueTag;

  /// No description provided for @paymentOnNextStep.
  ///
  /// In en, this message translates to:
  /// **'Payment on Next Step: '**
  String get paymentOnNextStep;

  /// No description provided for @paymentDetailsNotice.
  ///
  /// In en, this message translates to:
  /// **'Admin Payment QR code & bank transfer details on checkout page.'**
  String get paymentDetailsNotice;

  /// No description provided for @updateCalendarEvent.
  ///
  /// In en, this message translates to:
  /// **'Update Calendar Event'**
  String get updateCalendarEvent;

  /// No description provided for @updateEvent.
  ///
  /// In en, this message translates to:
  /// **'Update Event'**
  String get updateEvent;

  /// No description provided for @proceedToPayment.
  ///
  /// In en, this message translates to:
  /// **'Proceed to Payment'**
  String get proceedToPayment;

  /// No description provided for @uploadImage.
  ///
  /// In en, this message translates to:
  /// **'Upload Image'**
  String get uploadImage;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @eventDetails.
  ///
  /// In en, this message translates to:
  /// **'Event Details'**
  String get eventDetails;
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
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
