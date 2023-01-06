for i in $(seq 200 300); do
    curl 'https://blog.liaosirui.com/graphql' \
    -H 'authority: blog.liaosirui.com' \
    -H 'accept: */*' \
    -H 'accept-language: zh-CN,zh;q=0.9' \
    -H 'authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MSwiZW1haWwiOiJjeXJpbEBsaWFvc2lydWkuY29tIiwibmFtZSI6IlNpcnVpIExpYW8iLCJhdiI6bnVsbCwidHoiOiJBc2lhL1NoYW5naGFpIiwibGMiOiJlbiIsImRmIjoiIiwiYXAiOiIiLCJwZXJtaXNzaW9ucyI6WyJtYW5hZ2U6c3lzdGVtIl0sImdyb3VwcyI6WzFdLCJpYXQiOjE2NzI5NzM4MDIsImV4cCI6MTY3Mjk3NTYwMiwiYXVkIjoidXJuOndpa2kuanMiLCJpc3MiOiJ1cm46d2lraS5qcyJ9.VIICqhjyMwPxspNlCyVcrXQe3G5_9tLOFahNglA1-iZo5MadOuXhX38rq_QgB4o1bK_sHRmZI-OTHkUslx3BLOGptQ6FpRHI-nasZd8d4SvH8cHl2Aniq9gswxaWnbN6SLrAmb0hAPUcbCUoULfEsOQtBCCWzoFTsfx3QQXcLlN7ZIa2QmvH4CNQVzu_9fY5Or1eMFn2MUdSUMyRoSAd6Ml-k7-1XatyvoTwVQer9y-h6NK0j3ajFpOX77MxJnzzlSrAvf9P1OyT94N6d3qef1pIOAwxgbfJExjY_EoOjD75xAPqpbSCv7_SfP4zLtKgTDs9yxFAQqUG3rafLeRdSg' \
    -H 'content-type: application/json' \
    -H 'cookie: jwt=eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MSwiZW1haWwiOiJjeXJpbEBsaWFvc2lydWkuY29tIiwibmFtZSI6IlNpcnVpIExpYW8iLCJhdiI6bnVsbCwidHoiOiJBc2lhL1NoYW5naGFpIiwibGMiOiJlbiIsImRmIjoiIiwiYXAiOiIiLCJwZXJtaXNzaW9ucyI6WyJtYW5hZ2U6c3lzdGVtIl0sImdyb3VwcyI6WzFdLCJpYXQiOjE2NzI5NzM4MDIsImV4cCI6MTY3Mjk3NTYwMiwiYXVkIjoidXJuOndpa2kuanMiLCJpc3MiOiJ1cm46d2lraS5qcyJ9.VIICqhjyMwPxspNlCyVcrXQe3G5_9tLOFahNglA1-iZo5MadOuXhX38rq_QgB4o1bK_sHRmZI-OTHkUslx3BLOGptQ6FpRHI-nasZd8d4SvH8cHl2Aniq9gswxaWnbN6SLrAmb0hAPUcbCUoULfEsOQtBCCWzoFTsfx3QQXcLlN7ZIa2QmvH4CNQVzu_9fY5Or1eMFn2MUdSUMyRoSAd6Ml-k7-1XatyvoTwVQer9y-h6NK0j3ajFpOX77MxJnzzlSrAvf9P1OyT94N6d3qef1pIOAwxgbfJExjY_EoOjD75xAPqpbSCv7_SfP4zLtKgTDs9yxFAQqUG3rafLeRdSg' \
    -H 'origin: https://blog.liaosirui.com' \
    -H 'referer: https://blog.liaosirui.com/a/pages/678' \
    -H 'sec-ch-ua: "Chromium";v="106", "Google Chrome";v="106", "Not;A=Brand";v="99"' \
    -H 'sec-ch-ua-mobile: ?0' \
    -H 'sec-ch-ua-platform: "macOS"' \
    -H 'sec-fetch-dest: empty' \
    -H 'sec-fetch-mode: cors' \
    -H 'sec-fetch-site: same-origin' \
    -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36' \
    --data-raw $'[{"operationName":null,"variables":{"id": '${i}$'},"extensions":{},"query":"mutation ($id: Int\u0021) {\\n  pages {\\n    delete(id: $id) {\\n      responseResult {\\n        succeeded\\n        errorCode\\n        slug\\n        message\\n        __typename\\n      }\\n      __typename\\n    }\\n    __typename\\n  }\\n}\\n"}]' \
    --compressed
done
