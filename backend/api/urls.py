from django.urls import path

from api.views import (
    AnalyticsEventView,
    DiseaseDetailView,
    PopularDiseaseListView,
    FavoriteDeleteView,
    FavoriteListCreateView,
    HistoryListCreateView,
    PrivacyPolicyView,
    PushNotifyView,
    PushSubscribeView,
    PushUnsubscribeView,
    RemedyDetailView,
    RemedyListView,
    RemedyRateView,
    SearchView,
    SyncView,
    SymptomListView,
    TermsOfServiceView,
    UserConsentView,
)

urlpatterns = [
    path("sync/", SyncView.as_view(), name="sync"),
    path("symptoms/", SymptomListView.as_view(), name="symptom-list"),
    path("search/", SearchView.as_view(), name="search"),
    path(
        "diseases/popular/",
        PopularDiseaseListView.as_view(),
        name="popular-disease-list",
    ),
    path("remedies/", RemedyListView.as_view(), name="remedy-list"),
    path(
        "diseases/<int:disease_id>/", DiseaseDetailView.as_view(), name="disease-detail"
    ),
    path("remedies/<int:remedy_id>/", RemedyDetailView.as_view(), name="remedy-detail"),
    path(
        "remedies/<int:remedy_id>/rate/", RemedyRateView.as_view(), name="remedy-rate"
    ),
    path("favorites/", FavoriteListCreateView.as_view(), name="favorite-list-create"),
    path(
        "favorites/<int:remedy_id>/",
        FavoriteDeleteView.as_view(),
        name="favorite-delete",
    ),
    path("history/", HistoryListCreateView.as_view(), name="history-list-create"),
    path("legal/terms/", TermsOfServiceView.as_view(), name="legal-terms"),
    path("legal/privacy/", PrivacyPolicyView.as_view(), name="legal-privacy"),
    path("legal/consents/", UserConsentView.as_view(), name="legal-consent"),
    path("analytics/", AnalyticsEventView.as_view(), name="analytics"),
    path("push/subscribe/", PushSubscribeView.as_view(), name="push-subscribe"),
    path("push/unsubscribe/", PushUnsubscribeView.as_view(), name="push-unsubscribe"),
    path("push/notify/", PushNotifyView.as_view(), name="push-notify"),
]
