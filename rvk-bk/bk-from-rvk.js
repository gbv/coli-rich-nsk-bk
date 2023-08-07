#!/usr/bin/env node

// Liefert ausgehend von RVK-Notationen passende BK und Mapping-URIs

const request = async (api, query) => fetch(api + '?' + new URLSearchParams(query)).then(r => r.json())
const serialize = data => console.log(JSON.stringify(data))

const args = process.argv.slice(2)

for (let rvk of args) {
    let mappings = await request("https://coli-conc.gbv.de/api/mappings/infer", {
        from: rvk,
        fromScheme: 'http://bartoc.org/en/node/533', // RVK
        toScheme: 'http://bartoc.org/en/node/18785', // BK
        type: 'http://www.w3.org/2004/02/skos/core#exactMatch|http://www.w3.org/2004/02/skos/core#narrowMatch',
        properties: 'uri,partOf,annotations',
    })

    for (let m of mappings) {
        const to = m.to?.memberSet?.map(c => c.notation[0])
        if (!to.length) continue
        const uri = m.source ? m.source[0].uri : m.uri
        if (m.source) {
          [m] = await request("https://coli-conc.gbv.de/api/mappings", { uri, properties: "uri,partOf,annotations" })
        }
        const { partOf, annotations } = m
        if (annotations?.filter(a => a.bodyValue == "-1").length) {        
            // downgevoted
        } else if (partOf?.length) { // Teil einer Konkordanz
            for (let bk of to) {
                serialize({rvk, bk, uri})
            }
        }
    }
}
