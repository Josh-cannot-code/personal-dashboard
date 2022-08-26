FROM danielkun/elm-raspbian-arm32v7

COPY . .

RUN elm make

CMD ["./run.sh"]