from rest_framework import serializers


class SearchRequestSerializer(serializers.Serializer):
    symptoms = serializers.ListField(
        child=serializers.CharField(max_length=255),
        allow_empty=False,
    )


class SearchDiseaseSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    name = serializers.CharField()


class SearchResponseSerializer(serializers.Serializer):
    diseases = SearchDiseaseSerializer(many=True)


class EvidenceLevelSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    code = serializers.CharField()
    description = serializers.CharField()
    color = serializers.CharField()


class RatingSummarySerializer(serializers.Serializer):
    likes = serializers.IntegerField()
    dislikes = serializers.IntegerField()


class DiseaseRemedySerializer(serializers.Serializer):
    id = serializers.IntegerField()
    name = serializers.CharField()
    short_description = serializers.CharField()
    evidence_level = EvidenceLevelSerializer()
    rating = RatingSummarySerializer()


class DiseaseDetailSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    name = serializers.CharField()
    description = serializers.CharField()
    remedies = DiseaseRemedySerializer(many=True)


class RemedyIngredientSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    name = serializers.CharField()
    amount = serializers.CharField()


class RemedyDetailSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    disease_id = serializers.IntegerField()
    name = serializers.CharField()
    description = serializers.CharField()
    recipe = serializers.CharField()
    risks = serializers.CharField()
    source = serializers.CharField()
    evidence_level = EvidenceLevelSerializer()
    ingredients = RemedyIngredientSerializer(many=True)
    rating = RatingSummarySerializer()


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
