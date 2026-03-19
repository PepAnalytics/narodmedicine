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
    match_score = serializers.FloatField()
    symptoms = SearchMatchedSymptomSerializer(many=True)


class SearchResponseSerializer(serializers.Serializer):
    diseases = SearchDiseaseSerializer(many=True)


class SymptomListSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    name = serializers.CharField()


class BasicDiseaseSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    name = serializers.CharField()


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


class RemedyFullSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    disease_id = serializers.IntegerField()
    name = serializers.CharField()
    description = serializers.CharField()
    recipe = serializers.CharField()
    risks = serializers.CharField()
    source = serializers.CharField()
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
