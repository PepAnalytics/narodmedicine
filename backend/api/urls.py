from django.urls import path

from api.views import (
    DiseaseDetailView,
    FavoriteDeleteView,
    FavoriteListCreateView,
    HistoryListCreateView,
    RemedyDetailView,
    RemedyListView,
    RemedyRateView,
    SearchView,
    SyncView,
    SymptomListView,
)

urlpatterns = [
    path("sync/", SyncView.as_view(), name="sync"),
    path("symptoms/", SymptomListView.as_view(), name="symptom-list"),
    path("search/", SearchView.as_view(), name="search"),
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
]
