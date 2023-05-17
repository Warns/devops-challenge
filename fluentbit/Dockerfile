FROM public.ecr.aws/aws-observability/aws-for-fluent-bit:latest
RUN mkdir -p /fluent-bit/configs/custom
ADD multi_endpoints.conf /
ADD nested_fields.conf fluent-bit/configs/custom/
ADD parsers.conf fluent-bit/configs/custom/
ADD override_time.lua fluent-bit/configs/custom/
