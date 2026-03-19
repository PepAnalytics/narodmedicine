from rest_framework import serializers


class SearchRequestSerializer(serializers.Serializer):
    symptoms = serializers.ListField(
        child=serializers.CharField(max_length=255),
        allow_empty=False,
    )


class SearchMatchedSymptomSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    name = serializers.CharField()
    weight = serializers.FloatField()


class SearchDiseaseSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    name = serializers.CharField()
    description = serializers.CharField()
    short_description = serializers.CharField()
    match_score = serializers.FloatField()
    symptoms = SearchMatchedSymptomSerializer(many=True)
    matched_symptoms = SearchMatchedSymptomSerializer(many=True)


class SearchResponseSerializer(serializers.Serializer):
    diseases = SearchDiseaseSerializer(many=True)


class SymptomListSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    name = serializers.CharField()


class BasicDiseaseSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    name = serializers.CharField()


class SourceRecordSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    title = serializers.CharField()
    author = serializers.CharField(allow_blank=True)
    year = serializers.IntegerField(allow_null=True)
    region = serializers.CharField()
    source_type = serializers.CharField()
    url = serializers.CharField(allow_blank=True)
    reference = serializers.CharField(allow_blank=True)


class EvidenceLevelSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    code = serializers.CharField()
    description = serializers.CharField()
    color = serializers.CharField()
    rank = serializers.IntegerField()


class DiseaseRemedySerializer(serializers.Serializer):
    id = serializers.IntegerField()
    name = serializers.CharField()
    short_description = serializers.CharField()
    region = serializers.CharField()
    evidence_level = EvidenceLevelSerializer()
    likes_count = serializers.IntegerField()
    dislikes_count = serializers.IntegerField()


class DiseaseDetailSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    name = serializers.CharField()
    description = serializers.CharField()
    remedies = DiseaseRemedySerializer(many=True)


class RemedyIngredientSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    name = serializers.CharField()
    amount = serializers.CharField()
    alternative_names = serializers.JSONField()


class RemedyFullSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    disease_id = serializers.IntegerField()
    name = serializers.CharField()
    description = serializers.CharField()
    recipe = serializers.CharField()
    risks = serializers.CharField()
    source = serializers.CharField()
    source_record = SourceRecordSerializer(allow_null=True)
    region = serializers.CharField()
    cultural_context = serializers.CharField()
    evidence_level = EvidenceLevelSerializer()
    ingredients = RemedyIngredientSerializer(many=True)
    likes_count = serializers.IntegerField()
    dislikes_count = serializers.IntegerField()


class RemedyListResponseSerializer(serializers.Serializer):
    remedies = RemedyFullSerializer(many=True)


class RemedyRateRequestSerializer(serializers.Serializer):
    user_id = serializers.CharField(max_length=128)
    is_like = serializers.BooleanField()
    comment = serializers.CharField(required=False, allow_blank=True, allow_null=True)


class RemedyRateResponseSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    remedy = serializers.IntegerField()
    user_id = serializers.CharField()
    is_like = serializers.BooleanField()
    comment = serializers.CharField(allow_blank=True)
    created_at = serializers.DateTimeField()
    likes_count = serializers.IntegerField()
    dislikes_count = serializers.IntegerField()


class FavoriteCreateSerializer(serializers.Serializer):
    remedy_id = serializers.IntegerField()
    user_id = serializers.CharField(max_length=128, required=False, allow_blank=True)


class FavoriteDeleteResponseSerializer(serializers.Serializer):
    detail = serializers.CharField()


class FavoriteItemSerializer(serializers.Serializer):
    favorited_at = serializers.DateTimeField()
    remedy = RemedyFullSerializer()


class FavoriteListResponseSerializer(serializers.Serializer):
    page = serializers.IntegerField()
    page_size = serializers.IntegerField()
    total = serializers.IntegerField()
    favorites = FavoriteItemSerializer(many=True)


class HistoryCreateSerializer(serializers.Serializer):
    remedy_id = serializers.IntegerField()
    user_id = serializers.CharField(max_length=128, required=False, allow_blank=True)


class HistoryCreateResponseSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    user_id = serializers.CharField()
    remedy_id = serializers.IntegerField()
    viewed_at = serializers.DateTimeField()


class HistoryItemSerializer(serializers.Serializer):
    viewed_at = serializers.DateTimeField()
    remedy = RemedyFullSerializer()


class HistoryListResponseSerializer(serializers.Serializer):
    page = serializers.IntegerField()
    page_size = serializers.IntegerField()
    total = serializers.IntegerField()
    results = HistoryItemSerializer(many=True)


class SyncResponseSerializer(serializers.Serializer):
    symptoms = SymptomListSerializer(many=True)
    diseases = BasicDiseaseSerializer(many=True)
    evidence_levels = EvidenceLevelSerializer(many=True)


class PopularDiseaseSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    name = serializers.CharField()
    description = serializers.CharField()
    short_description = serializers.CharField()
    remedies_count = serializers.IntegerField()
    popularity_score = serializers.IntegerField()


class PopularDiseaseListResponseSerializer(serializers.Serializer):
    diseases = PopularDiseaseSerializer(many=True)


class HealthResponseSerializer(serializers.Serializer):
    status = serializers.CharField()
    service = serializers.CharField()
    version = serializers.CharField()
    timestamp = serializers.DateTimeField()


class ReadinessResponseSerializer(serializers.Serializer):
    status = serializers.CharField()
    service = serializers.CharField()
    version = serializers.CharField()
    timestamp = serializers.DateTimeField()
    checks = serializers.JSONField()


class PushSubscribeRequestSerializer(serializers.Serializer):
    user_id = serializers.CharField(max_length=128, required=False, allow_blank=True)
    fcm_token = serializers.CharField(max_length=512)
    platform = serializers.ChoiceField(
        choices=("android", "ios", "web", "other"),
        required=False,
        default="other",
    )


class PushDeviceSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    user_id = serializers.CharField()
    fcm_token = serializers.CharField()
    platform = serializers.CharField()
    is_active = serializers.BooleanField()
    created_at = serializers.DateTimeField()
    updated_at = serializers.DateTimeField()
    last_seen_at = serializers.DateTimeField()


class PushUnsubscribeRequestSerializer(serializers.Serializer):
    user_id = serializers.CharField(max_length=128, required=False, allow_blank=True)
    fcm_token = serializers.CharField(max_length=512)


class PushUnsubscribeResponseSerializer(serializers.Serializer):
    detail = serializers.CharField()


class PushNotifyRequestSerializer(serializers.Serializer):
    user_id = serializers.CharField(max_length=128, required=False, allow_blank=True)
    title = serializers.CharField(max_length=120)
    body = serializers.CharField(max_length=1024)
    data = serializers.DictField(
        child=serializers.CharField(),
        required=False,
        default=dict,
    )
    tokens = serializers.ListField(
        child=serializers.CharField(max_length=512),
        required=False,
        allow_empty=False,
    )
    dry_run = serializers.BooleanField(required=False, default=False)

    def validate(self, attrs: dict) -> dict:
        if attrs.get("user_id"):
            return attrs
        if attrs.get("tokens"):
            return attrs
        request = self.context.get("request")
        if request is not None:
            for candidate in (
                request.headers.get("X-User-Id"),
                request.query_params.get("user_id"),
            ):
                if candidate and str(candidate).strip():
                    return attrs
        raise serializers.ValidationError(
            "Provide user_id or explicit tokens list for delivery.",
        )


class PushNotifyResultSerializer(serializers.Serializer):
    token = serializers.CharField()
    status = serializers.CharField()
    message_id = serializers.CharField(required=False, allow_blank=True)
    error = serializers.CharField(required=False, allow_blank=True)


class PushNotifyResponseSerializer(serializers.Serializer):
    requested = serializers.IntegerField()
    sent = serializers.IntegerField()
    failed = serializers.IntegerField()
    results = PushNotifyResultSerializer(many=True)


class LegalDocumentSerializer(serializers.Serializer):
    document_type = serializers.CharField()
    version = serializers.CharField()
    content = serializers.CharField()
    effective_from = serializers.DateTimeField()
    created_at = serializers.DateTimeField()


class UserConsentRequestSerializer(serializers.Serializer):
    user_id = serializers.CharField(max_length=128, required=False, allow_blank=True)
    document_type = serializers.ChoiceField(
        choices=("terms_of_service", "privacy_policy")
    )
    version = serializers.CharField(max_length=32)


class UserConsentResponseSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    user_id = serializers.CharField()
    document_type = serializers.CharField()
    version = serializers.CharField()
    timestamp = serializers.DateTimeField()


class AnalyticsEventRequestSerializer(serializers.Serializer):
    user_id = serializers.CharField(max_length=128, required=False, allow_blank=True)
    event_type = serializers.CharField(max_length=128)
    metadata = serializers.JSONField(required=False, default=dict)


class AnalyticsEventResponseSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    user_id = serializers.CharField(allow_blank=True)
    event_type = serializers.CharField()
    metadata = serializers.JSONField()
    timestamp = serializers.DateTimeField()
