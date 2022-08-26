FROM danielkun/elm-raspbian-arm32v7

COPY . .

RUN elm install elm-lang/cor

RUN elm make

CMD ["./run.sh"]