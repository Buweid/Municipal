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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Muscat Municipality'**
  String get appName;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @nationalId.
  ///
  /// In en, this message translates to:
  /// **'National ID'**
  String get nationalId;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotifications;

  /// No description provided for @adminDashboard.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get adminDashboard;

  /// No description provided for @welcomeAdmin.
  ///
  /// In en, this message translates to:
  /// **'Welcome, Administrator'**
  String get welcomeAdmin;

  /// No description provided for @municipalitySystem.
  ///
  /// In en, this message translates to:
  /// **'Muscat Municipality Reporting System'**
  String get municipalitySystem;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @totalIssues.
  ///
  /// In en, this message translates to:
  /// **'Total Issues'**
  String get totalIssues;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @resolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get resolved;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @citizens.
  ///
  /// In en, this message translates to:
  /// **'Citizens'**
  String get citizens;

  /// No description provided for @fieldOfficers.
  ///
  /// In en, this message translates to:
  /// **'Field Officers'**
  String get fieldOfficers;

  /// No description provided for @manageIssues.
  ///
  /// In en, this message translates to:
  /// **'Manage Issues'**
  String get manageIssues;

  /// No description provided for @manageUsers.
  ///
  /// In en, this message translates to:
  /// **'Manage Users'**
  String get manageUsers;

  /// No description provided for @addFieldOfficer.
  ///
  /// In en, this message translates to:
  /// **'Add Field Officer'**
  String get addFieldOfficer;

  /// No description provided for @manageIssueTypes.
  ///
  /// In en, this message translates to:
  /// **'Manage Issue Types'**
  String get manageIssueTypes;

  /// No description provided for @issuesMap.
  ///
  /// In en, this message translates to:
  /// **'Issues Map'**
  String get issuesMap;

  /// No description provided for @analyticsReports.
  ///
  /// In en, this message translates to:
  /// **'Analytics & Reports'**
  String get analyticsReports;

  /// No description provided for @activityLog.
  ///
  /// In en, this message translates to:
  /// **'Activity Log'**
  String get activityLog;

  /// No description provided for @feedbackRatings.
  ///
  /// In en, this message translates to:
  /// **'Feedback & Ratings'**
  String get feedbackRatings;

  /// No description provided for @broadcastNotifications.
  ///
  /// In en, this message translates to:
  /// **'Broadcast Notifications'**
  String get broadcastNotifications;

  /// No description provided for @aiAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get aiAssistant;

  /// No description provided for @myReports.
  ///
  /// In en, this message translates to:
  /// **'My Reports'**
  String get myReports;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @noReportsYet.
  ///
  /// In en, this message translates to:
  /// **'No reports yet'**
  String get noReportsYet;

  /// No description provided for @tapToSubmit.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Submit Report\" to get started'**
  String get tapToSubmit;

  /// No description provided for @submitReport.
  ///
  /// In en, this message translates to:
  /// **'Submit Report'**
  String get submitReport;

  /// No description provided for @seeMoreIssues.
  ///
  /// In en, this message translates to:
  /// **'See something that needs fixing?'**
  String get seeMoreIssues;

  /// No description provided for @reportInSeconds.
  ///
  /// In en, this message translates to:
  /// **'Report it to your municipality in seconds.'**
  String get reportInSeconds;

  /// No description provided for @recentReports.
  ///
  /// In en, this message translates to:
  /// **'Recent Reports'**
  String get recentReports;

  /// No description provided for @myTasks.
  ///
  /// In en, this message translates to:
  /// **'My Tasks'**
  String get myTasks;

  /// No description provided for @taskOverview.
  ///
  /// In en, this message translates to:
  /// **'Task Overview'**
  String get taskOverview;

  /// No description provided for @pendingTasks.
  ///
  /// In en, this message translates to:
  /// **'Pending Tasks'**
  String get pendingTasks;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @noPendingTasks.
  ///
  /// In en, this message translates to:
  /// **'No pending tasks 🎉'**
  String get noPendingTasks;

  /// No description provided for @viewTasks.
  ///
  /// In en, this message translates to:
  /// **'View Tasks →'**
  String get viewTasks;

  /// No description provided for @yourTasksToday.
  ///
  /// In en, this message translates to:
  /// **'Your tasks\nfor today'**
  String get yourTasksToday;

  /// No description provided for @newTasks.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newTasks;

  /// No description provided for @doneTasks.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneTasks;

  /// No description provided for @submitIssue.
  ///
  /// In en, this message translates to:
  /// **'Submit Issue'**
  String get submitIssue;

  /// No description provided for @issueTitle.
  ///
  /// In en, this message translates to:
  /// **'Issue Title'**
  String get issueTitle;

  /// No description provided for @issueType.
  ///
  /// In en, this message translates to:
  /// **'Issue Type'**
  String get issueType;

  /// No description provided for @selectIssueType.
  ///
  /// In en, this message translates to:
  /// **'Select issue type'**
  String get selectIssueType;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @describeIssue.
  ///
  /// In en, this message translates to:
  /// **'Describe the issue in detail...'**
  String get describeIssue;

  /// No description provided for @photoEvidence.
  ///
  /// In en, this message translates to:
  /// **'Photo Evidence'**
  String get photoEvidence;

  /// No description provided for @tapToAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Tap to add photo (optional)'**
  String get tapToAddPhoto;

  /// No description provided for @issueLocation.
  ///
  /// In en, this message translates to:
  /// **'Issue Location'**
  String get issueLocation;

  /// No description provided for @tapToSelectLocation.
  ///
  /// In en, this message translates to:
  /// **'Tap to select location on map'**
  String get tapToSelectLocation;

  /// No description provided for @locationSelected.
  ///
  /// In en, this message translates to:
  /// **'Location Selected ✅'**
  String get locationSelected;

  /// No description provided for @submitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting...'**
  String get submitting;

  /// No description provided for @improveWithAI.
  ///
  /// In en, this message translates to:
  /// **'Improve with AI'**
  String get improveWithAI;

  /// No description provided for @issueSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Issue submitted successfully ✅'**
  String get issueSubmitted;

  /// No description provided for @myIssues.
  ///
  /// In en, this message translates to:
  /// **'My Issues'**
  String get myIssues;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @rateNow.
  ///
  /// In en, this message translates to:
  /// **'Rate now'**
  String get rateNow;

  /// No description provided for @noIssuesYet.
  ///
  /// In en, this message translates to:
  /// **'No issues submitted yet'**
  String get noIssuesYet;

  /// No description provided for @pickLocation.
  ///
  /// In en, this message translates to:
  /// **'Pick Location'**
  String get pickLocation;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @tapMapToSelect.
  ///
  /// In en, this message translates to:
  /// **'Tap on the map to select the issue location'**
  String get tapMapToSelect;

  /// No description provided for @updateProfile.
  ///
  /// In en, this message translates to:
  /// **'Update Profile'**
  String get updateProfile;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @changing.
  ///
  /// In en, this message translates to:
  /// **'Changing...'**
  String get changing;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @switchTheme.
  ///
  /// In en, this message translates to:
  /// **'Switch between light and dark'**
  String get switchTheme;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @issueUpdates.
  ///
  /// In en, this message translates to:
  /// **'Issue Updates'**
  String get issueUpdates;

  /// No description provided for @notifyStatusChange.
  ///
  /// In en, this message translates to:
  /// **'Notify when issue status changes'**
  String get notifyStatusChange;

  /// No description provided for @broadcastMessages.
  ///
  /// In en, this message translates to:
  /// **'Broadcast Messages'**
  String get broadcastMessages;

  /// No description provided for @messagesFromAdmin.
  ///
  /// In en, this message translates to:
  /// **'Messages from municipality admin'**
  String get messagesFromAdmin;

  /// No description provided for @taskNotifications.
  ///
  /// In en, this message translates to:
  /// **'Task Notifications'**
  String get taskNotifications;

  /// No description provided for @notifyTaskAssigned.
  ///
  /// In en, this message translates to:
  /// **'Notify when a task is assigned'**
  String get notifyTaskAssigned;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersion;

  /// No description provided for @aiAssistantTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get aiAssistantTitle;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type your message...'**
  String get typeMessage;

  /// No description provided for @quickQuestions.
  ///
  /// In en, this message translates to:
  /// **'Quick questions:'**
  String get quickQuestions;

  /// No description provided for @howSubmitReport.
  ///
  /// In en, this message translates to:
  /// **'How do I submit a report?'**
  String get howSubmitReport;

  /// No description provided for @howTrackIssue.
  ///
  /// In en, this message translates to:
  /// **'How can I track my issue?'**
  String get howTrackIssue;

  /// No description provided for @whatTypesIssues.
  ///
  /// In en, this message translates to:
  /// **'What types of issues can I report?'**
  String get whatTypesIssues;

  /// No description provided for @howLongResolve.
  ///
  /// In en, this message translates to:
  /// **'How long does it take to resolve?'**
  String get howLongResolve;

  /// No description provided for @issueManagement.
  ///
  /// In en, this message translates to:
  /// **'Issue Management'**
  String get issueManagement;

  /// No description provided for @approveIssue.
  ///
  /// In en, this message translates to:
  /// **'Approve Issue'**
  String get approveIssue;

  /// No description provided for @rejectIssue.
  ///
  /// In en, this message translates to:
  /// **'Reject Issue'**
  String get rejectIssue;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @assignToFO.
  ///
  /// In en, this message translates to:
  /// **'Assign to Field Officer'**
  String get assignToFO;

  /// No description provided for @assign.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get assign;

  /// No description provided for @updateStatus.
  ///
  /// In en, this message translates to:
  /// **'Update Status'**
  String get updateStatus;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @reportedBy.
  ///
  /// In en, this message translates to:
  /// **'Reported by'**
  String get reportedBy;

  /// No description provided for @submitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get submitted;

  /// No description provided for @locationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationLabel;

  /// No description provided for @noIssuesSubmitted.
  ///
  /// In en, this message translates to:
  /// **'No issues submitted yet'**
  String get noIssuesSubmitted;

  /// No description provided for @manageUsersTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Users'**
  String get manageUsersTitle;

  /// No description provided for @searchByNameEmail.
  ///
  /// In en, this message translates to:
  /// **'Search by name or email...'**
  String get searchByNameEmail;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @citizen.
  ///
  /// In en, this message translates to:
  /// **'Citizen'**
  String get citizen;

  /// No description provided for @fieldOfficer.
  ///
  /// In en, this message translates to:
  /// **'Field Officer'**
  String get fieldOfficer;

  /// No description provided for @noUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get noUsersFound;

  /// No description provided for @editUser.
  ///
  /// In en, this message translates to:
  /// **'Edit User'**
  String get editUser;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @userUpdated.
  ///
  /// In en, this message translates to:
  /// **'User updated successfully ✅'**
  String get userUpdated;

  /// No description provided for @manageIssueTypesTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Issue Types'**
  String get manageIssueTypesTitle;

  /// No description provided for @addNewIssueType.
  ///
  /// In en, this message translates to:
  /// **'Add New Issue Type'**
  String get addNewIssueType;

  /// No description provided for @issueTypeName.
  ///
  /// In en, this message translates to:
  /// **'Issue Type Name'**
  String get issueTypeName;

  /// No description provided for @selectIcon.
  ///
  /// In en, this message translates to:
  /// **'Select Icon'**
  String get selectIcon;

  /// No description provided for @addIssueType.
  ///
  /// In en, this message translates to:
  /// **'Add Issue Type'**
  String get addIssueType;

  /// No description provided for @adding.
  ///
  /// In en, this message translates to:
  /// **'Adding...'**
  String get adding;

  /// No description provided for @existingIssueTypes.
  ///
  /// In en, this message translates to:
  /// **'Existing Issue Types'**
  String get existingIssueTypes;

  /// No description provided for @noIssueTypesYet.
  ///
  /// In en, this message translates to:
  /// **'No issue types yet'**
  String get noIssueTypesYet;

  /// No description provided for @deleteIssueType.
  ///
  /// In en, this message translates to:
  /// **'Delete Issue Type'**
  String get deleteIssueType;

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete'**
  String get deleteConfirm;

  /// No description provided for @analyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Analytics & Reports'**
  String get analyticsTitle;

  /// No description provided for @avgRating.
  ///
  /// In en, this message translates to:
  /// **'Avg Rating'**
  String get avgRating;

  /// No description provided for @resolutionRate.
  ///
  /// In en, this message translates to:
  /// **'Resolution Rate'**
  String get resolutionRate;

  /// No description provided for @issuesByStatus.
  ///
  /// In en, this message translates to:
  /// **'Issues by Status'**
  String get issuesByStatus;

  /// No description provided for @monthlyIssues.
  ///
  /// In en, this message translates to:
  /// **'Monthly Issues (Last 6 Months)'**
  String get monthlyIssues;

  /// No description provided for @issuesByType.
  ///
  /// In en, this message translates to:
  /// **'Issues by Type'**
  String get issuesByType;

  /// No description provided for @generatePDF.
  ///
  /// In en, this message translates to:
  /// **'Generate PDF Report'**
  String get generatePDF;

  /// No description provided for @generating.
  ///
  /// In en, this message translates to:
  /// **'Generating...'**
  String get generating;

  /// No description provided for @feedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Feedback & Ratings'**
  String get feedbackTitle;

  /// No description provided for @allFeedback.
  ///
  /// In en, this message translates to:
  /// **'All Feedback'**
  String get allFeedback;

  /// No description provided for @responded.
  ///
  /// In en, this message translates to:
  /// **'Responded'**
  String get responded;

  /// No description provided for @awaitingResponse.
  ///
  /// In en, this message translates to:
  /// **'Awaiting Response'**
  String get awaitingResponse;

  /// No description provided for @totalReviews.
  ///
  /// In en, this message translates to:
  /// **'Total Reviews'**
  String get totalReviews;

  /// No description provided for @respondToFeedback.
  ///
  /// In en, this message translates to:
  /// **'Respond to Feedback'**
  String get respondToFeedback;

  /// No description provided for @editResponse.
  ///
  /// In en, this message translates to:
  /// **'Edit Response'**
  String get editResponse;

  /// No description provided for @respond.
  ///
  /// In en, this message translates to:
  /// **'Respond'**
  String get respond;

  /// No description provided for @noFeedbackYet.
  ///
  /// In en, this message translates to:
  /// **'No feedback yet'**
  String get noFeedbackYet;

  /// No description provided for @adminResponse.
  ///
  /// In en, this message translates to:
  /// **'Admin Response'**
  String get adminResponse;

  /// No description provided for @yourResponse.
  ///
  /// In en, this message translates to:
  /// **'Your Response'**
  String get yourResponse;

  /// No description provided for @broadcastTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification Management'**
  String get broadcastTitle;

  /// No description provided for @broadcast.
  ///
  /// In en, this message translates to:
  /// **'Broadcast'**
  String get broadcast;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @targetAudience.
  ///
  /// In en, this message translates to:
  /// **'Target Audience'**
  String get targetAudience;

  /// No description provided for @notificationContent.
  ///
  /// In en, this message translates to:
  /// **'Notification Content'**
  String get notificationContent;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @sendBroadcast.
  ///
  /// In en, this message translates to:
  /// **'Send Broadcast'**
  String get sendBroadcast;

  /// No description provided for @sending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get sending;

  /// No description provided for @noBroadcastsYet.
  ///
  /// In en, this message translates to:
  /// **'No broadcasts sent yet'**
  String get noBroadcastsYet;

  /// No description provided for @recipients.
  ///
  /// In en, this message translates to:
  /// **'recipients'**
  String get recipients;

  /// No description provided for @auditLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity Log'**
  String get auditLogTitle;

  /// No description provided for @noActivityYet.
  ///
  /// In en, this message translates to:
  /// **'No activity logs yet'**
  String get noActivityYet;

  /// No description provided for @issuesMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Issues Map'**
  String get issuesMapTitle;

  /// No description provided for @issueMap.
  ///
  /// In en, this message translates to:
  /// **'Issue Map'**
  String get issueMap;

  /// No description provided for @heatMap.
  ///
  /// In en, this message translates to:
  /// **'Heat Map'**
  String get heatMap;

  /// No description provided for @issueDensity.
  ///
  /// In en, this message translates to:
  /// **'Issue Density'**
  String get issueDensity;

  /// No description provided for @low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get low;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get high;

  /// No description provided for @critical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get critical;

  /// No description provided for @totalIssuesMap.
  ///
  /// In en, this message translates to:
  /// **'total issues'**
  String get totalIssuesMap;

  /// No description provided for @rateService.
  ///
  /// In en, this message translates to:
  /// **'Rate Service'**
  String get rateService;

  /// No description provided for @satisfactionQuestion.
  ///
  /// In en, this message translates to:
  /// **'How satisfied are you with the resolution?'**
  String get satisfactionQuestion;

  /// No description provided for @tapStarToRate.
  ///
  /// In en, this message translates to:
  /// **'Tap a star to rate'**
  String get tapStarToRate;

  /// No description provided for @veryUnsatisfied.
  ///
  /// In en, this message translates to:
  /// **'😞 Very Unsatisfied'**
  String get veryUnsatisfied;

  /// No description provided for @unsatisfied.
  ///
  /// In en, this message translates to:
  /// **'😕 Unsatisfied'**
  String get unsatisfied;

  /// No description provided for @neutral.
  ///
  /// In en, this message translates to:
  /// **'😐 Neutral'**
  String get neutral;

  /// No description provided for @satisfied.
  ///
  /// In en, this message translates to:
  /// **'😊 Satisfied'**
  String get satisfied;

  /// No description provided for @verySatisfied.
  ///
  /// In en, this message translates to:
  /// **'😄 Very Satisfied'**
  String get verySatisfied;

  /// No description provided for @commentOptional.
  ///
  /// In en, this message translates to:
  /// **'Comment (optional)'**
  String get commentOptional;

  /// No description provided for @shareExperience.
  ///
  /// In en, this message translates to:
  /// **'Share your experience...'**
  String get shareExperience;

  /// No description provided for @submitRating.
  ///
  /// In en, this message translates to:
  /// **'Submit Rating'**
  String get submitRating;

  /// No description provided for @thankYouFeedback.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your feedback ⭐'**
  String get thankYouFeedback;

  /// No description provided for @yourRating.
  ///
  /// In en, this message translates to:
  /// **'Your Rating'**
  String get yourRating;

  /// No description provided for @rateThisService.
  ///
  /// In en, this message translates to:
  /// **'Rate This Service'**
  String get rateThisService;

  /// No description provided for @acceptTask.
  ///
  /// In en, this message translates to:
  /// **'Accept Task'**
  String get acceptTask;

  /// No description provided for @rejectTask.
  ///
  /// In en, this message translates to:
  /// **'Reject Task'**
  String get rejectTask;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @updateProgress.
  ///
  /// In en, this message translates to:
  /// **'Update Progress'**
  String get updateProgress;

  /// No description provided for @uploadEvidence.
  ///
  /// In en, this message translates to:
  /// **'Upload Evidence Photo'**
  String get uploadEvidence;

  /// No description provided for @replaceEvidence.
  ///
  /// In en, this message translates to:
  /// **'Replace Evidence Photo'**
  String get replaceEvidence;

  /// No description provided for @taskCompleted.
  ///
  /// In en, this message translates to:
  /// **'Task completed ✅'**
  String get taskCompleted;

  /// No description provided for @taskRejected.
  ///
  /// In en, this message translates to:
  /// **'Task Rejected'**
  String get taskRejected;

  /// No description provided for @noTasksAssigned.
  ///
  /// In en, this message translates to:
  /// **'No tasks assigned to you yet'**
  String get noTasksAssigned;

  /// No description provided for @issuePending.
  ///
  /// In en, this message translates to:
  /// **'pending'**
  String get issuePending;

  /// No description provided for @confirmAcceptTask.
  ///
  /// In en, this message translates to:
  /// **'Confirm you are accepting this task?'**
  String get confirmAcceptTask;

  /// No description provided for @reasonRejection.
  ///
  /// In en, this message translates to:
  /// **'Reason for rejection'**
  String get reasonRejection;

  /// No description provided for @explainRejection.
  ///
  /// In en, this message translates to:
  /// **'Explain why you cannot take this task...'**
  String get explainRejection;

  /// No description provided for @moveTaskTo.
  ///
  /// In en, this message translates to:
  /// **'Move task to'**
  String get moveTaskTo;

  /// No description provided for @issuePhoto.
  ///
  /// In en, this message translates to:
  /// **'Issue Photo'**
  String get issuePhoto;

  /// No description provided for @completionEvidence.
  ///
  /// In en, this message translates to:
  /// **'Completion Evidence'**
  String get completionEvidence;

  /// No description provided for @passwordResetSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent — check your inbox'**
  String get passwordResetSent;

  /// No description provided for @accountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully'**
  String get accountCreated;

  /// No description provided for @loginSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Login Successful'**
  String get loginSuccessful;

  /// No description provided for @foCreated.
  ///
  /// In en, this message translates to:
  /// **'Field Officer created successfully ✅'**
  String get foCreated;
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
