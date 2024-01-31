FROM public.ecr.aws/amazonlinux/amazonlinux:2

WORKDIR /app

COPY match .

RUN yum install -y shadow-utils

RUN useradd match \
    && chown -R match:match /app \
    && chmod 755 /app
USER match

CMD ["./match"]