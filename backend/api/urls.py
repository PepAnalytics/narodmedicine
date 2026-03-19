from django.urls import path

from api.views import (
    DiseaseDetailView,
    RemedyDetailView,
    RemedyRateView,
    SearchView,
    SymptomListView,
)

urlpatterns = [
    path("symptoms/", SymptomListView.as_view(), name="symptom-list"),
    path("search/", SearchView.as_view(), name="search"),
    path(
        "diseases/<int:disease_id>/", DiseaseDetailView.as_view(), name="disease-detail"
    ),
    path("remedies/<int:remedy_id>/", RemedyDetailView.as_view(), name="remedy-detail"),
    path(
        "remedies/<int:remedy_id>/rate/", RemedyRateView.as_view(), name="remedy-rate"
    ),
]
