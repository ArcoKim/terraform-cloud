FROM public.ecr.aws/amazonlinux/amazonlinux:2

WORKDIR /app

COPY stress .

RUN yum install -y shadow-utils

RUN useradd stress \
    && chown -R stress:stress /app \
    && chmod 755 /app
USER stress

CMD ["./stress"]