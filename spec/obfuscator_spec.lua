local lu = require('luaunit')
local obfuscator = require('../src/obfuscator')
local cjson = require "cjson"
-- test = '{ "destination_addresses": [ "Washington, DC, USA", "Philadelphia, PA, USA", "Santa Barbara, CA, USA", "Miami, FL, USA", "Austin, TX, USA", "Napa County, CA, USA" ], "origin_addresses": [ "New York, NY, USA" ], "rows": [{ "elements": [{ "distance": { "text": "227 mi", "value": 365468 }, "duration": { "text": "3 hours 54 mins", "value": 14064 }, "status": "OK" }, { "distance": { "text": "94.6 mi", "value": 152193 }, "duration": { "text": "1 hour 44 mins", "value": 6227 }, "status": "OK" }, { "distance": { "text": "2,878 mi", "value": 4632197 }, "duration": { "text": "1 day 18 hours", "value": 151772 }, "status": "OK" }, { "distance": { "text": "1,286 mi", "value": 2069031 }, "duration": { "text": "18 hours 43 mins", "value": 67405 }, "status": "OK" }, { "distance": { "text": "1,742 mi", "value": 2802972 }, "duration": { "text": "1 day 2 hours", "value": 93070 }, "status": "OK" }, { "distance": { "text": "2,871 mi", "value": 4620514 }, "duration": { "text": "1 day 18 hours", "value": 152913 }, "status": "OK" } ] }], "status": "OK" }'

TestObfuscate = {} --class
    function TestObfuscate:testNilKeysToObfuscate()
        testJson = '{"creditCard":{"expiryDate":"10/21","cardNumber":"4976416038574166"},"accountIdentifier":"mb2","accountType":"retail"}'
        keysToObfuscate = nil
        mask = '***'

        responseString = obfuscator.obfuscate(testJson, nil, mask)
        response = cjson.decode(responseString)
        lu.assertEquals( response.creditCard.cardNumber, '4976416038574166')
    end

    function TestObfuscate:testNoKeysToObfuscate()
        testJson = '{"creditCard":{"expiryDate":"10/21","cardNumber":"4976416038574166"},"accountIdentifier":"mb2","accountType":"retail"}'
        keysToObfuscate = '[]'
        mask = '***'

        responseString = obfuscator.obfuscate(testJson, nil, mask)
        response = cjson.decode(responseString)
        lu.assertEquals( response.creditCard.cardNumber, '4976416038574166')
    end

    function TestObfuscate:testObject()
        testJson = '{"creditCard":{"expiryDate":"10/21","cardNumber":"4976416038574166"},"accountIdentifier":"mb2","accountType":"retail"}'
        keysToObfuscate = '["cardNumber"]'
        mask = '***'

        ktoObj = cjson.decode(keysToObfuscate)
        responseString = obfuscator.obfuscate(testJson, ktoObj, mask)
        response = cjson.decode(responseString)
        lu.assertEquals( response.creditCard.cardNumber, mask)
    end

    function TestObfuscate:testArray()
        testJson = '[{"creditCard":{"expiryDate":"10/21","cardNumber":"4976416038574166"},"accountIdentifier":"mb2","accountType":"retail"}]'
        keysToObfuscate = '["cardNumber"]'
        mask = '***'

        ktoObj = cjson.decode(keysToObfuscate)
        responseString = obfuscator.obfuscate(testJson, ktoObj, mask)
        response = cjson.decode(responseString)
        lu.assertEquals( response[1].creditCard.cardNumber, mask)
    end

    function TestObfuscate:testBigObject()
        testJson = '{ "destination_addresses": [ "Washington, DC, USA", "Philadelphia, PA, USA", "Santa Barbara, CA, USA", "Miami, FL, USA", "Austin, TX, USA", "Napa County, CA, USA" ], "origin_addresses": [ "New York, NY, USA" ], "rows": [{ "elements": [{ "distance": { "text": "227 mi", "value": 365468 }, "duration": { "text": "3 hours 54 mins", "value": 14064 }, "status": "OK" }, { "distance": { "text": "94.6 mi", "value": 152193 }, "duration": { "text": "1 hour 44 mins", "value": 6227 }, "status": "OK" }, { "distance": { "text": "2,878 mi", "value": 4632197 }, "duration": { "text": "1 day 18 hours", "value": 151772 }, "status": "OK" }, { "distance": { "text": "1,286 mi", "value": 2069031 }, "duration": { "text": "18 hours 43 mins", "value": 67405 }, "status": "OK" }, { "distance": { "text": "1,742 mi", "value": 2802972 }, "duration": { "text": "1 day 2 hours", "value": 93070 }, "status": "OK" }, { "distance": { "text": "2,871 mi", "value": 4620514 }, "duration": { "text": "1 day 18 hours", "value": 152913 }, "status": "OK" } ] }], "status": "OK" }'
        keysToObfuscate = '["text"]'
        mask = '***'

        ktoObj = cjson.decode(keysToObfuscate)
        responseString = obfuscator.obfuscate(testJson, ktoObj, mask)
        response = cjson.decode(responseString)
        for k, v in pairs(response.rows[1].elements) do
            lu.assertEquals( v.distance.text, mask)
        end
    end

    function TestObfuscate:testDifferentMask()
        testJson = '{ "destination_addresses": [ "Washington, DC, USA", "Philadelphia, PA, USA", "Santa Barbara, CA, USA", "Miami, FL, USA", "Austin, TX, USA", "Napa County, CA, USA" ], "origin_addresses": [ "New York, NY, USA" ], "rows": [{ "elements": [{ "distance": { "text": "227 mi", "value": 365468 }, "duration": { "text": "3 hours 54 mins", "value": 14064 }, "status": "OK" }, { "distance": { "text": "94.6 mi", "value": 152193 }, "duration": { "text": "1 hour 44 mins", "value": 6227 }, "status": "OK" }, { "distance": { "text": "2,878 mi", "value": 4632197 }, "duration": { "text": "1 day 18 hours", "value": 151772 }, "status": "OK" }, { "distance": { "text": "1,286 mi", "value": 2069031 }, "duration": { "text": "18 hours 43 mins", "value": 67405 }, "status": "OK" }, { "distance": { "text": "1,742 mi", "value": 2802972 }, "duration": { "text": "1 day 2 hours", "value": 93070 }, "status": "OK" }, { "distance": { "text": "2,871 mi", "value": 4620514 }, "duration": { "text": "1 day 18 hours", "value": 152913 }, "status": "OK" } ] }], "status": "OK" }'
        keysToObfuscate = '["text"]'
        mask = 'differentmask'

        ktoObj = cjson.decode(keysToObfuscate)
        responseString = obfuscator.obfuscate(testJson, ktoObj, mask)
        response = cjson.decode(responseString)
        for k, v in pairs(response.rows[1].elements) do
            lu.assertEquals( v.distance.text, mask)
        end
    end

    function TestObfuscate:testEscape()
        testJson = '{ "pan": "0123456789", "url": "http://www.someurl.com/test/try"}'
        keysToObfuscate = '["text"]'
        mask = 'differentmask'

        ktoObj = cjson.decode(keysToObfuscate)
        responseString = obfuscator.obfuscate(testJson, ktoObj, mask)
        response = cjson.decode(responseString)
        lu.assertEquals(response.url, 'http://www.someurl.com/test/try')
    end

    function TestObfuscate:testEnriquez()
        testJson = '{"deviceInfo":{"os":"android","osVersion":"10","deviceType":"phone","deviceModel":"Nokia 7 plus","deviceName":"HMD Global Nokia 7 plus","platformData":{"ios":null,"android":{"build":"QKQ1.190828.002","manufacturer":"HMD Global","apilevel":"29","device":"B2N_sprout","serial":"unknown","brand":"Nokia","androidId":"abf9ddd127cf4f5f","product":"Onyx_00WW","hardware":"qcom","type":"user","nfcCapable":true}}},"appInstanceId":"a5800316-2507-4dfd-9c11-5300472575ff","creationDate":"2020-02-18T08:45:13.206Z","lastUpdate":"2020-02-19T08:08:29.881Z","pushTokens":[{"token":"cjimUWUvKNE:APA91bGB1VKT73KCX6DpnxnMfPOcUkF63OpsbCYpxmcvybduXt8gDN8GVO8WtP7n9Hjv-pya_mdXy2phwupgjQE-ch0lE6ZIKFm9rLMJSh44clm_IlmMA65ivJAF4ZHokHNc8i1gYdtb","scope":"DEFAULT","status":"active"}]}'
        keysToObfuscate = '["os"]'
        mask = '***'

        ktoObj = cjson.decode(keysToObfuscate)
        responseString = obfuscator.obfuscate(testJson, ktoObj, mask)
        response = cjson.decode(responseString)
        lu.assertEquals( response.deviceInfo.os, '***')
    end

    function TestObfuscate:testInvalidJson()
        testJson = '{"text": "invalidjson}'
        keysToObfuscate = '["os"]'
        mask = '***'

        ktoObj = cjson.decode(keysToObfuscate)
        status, errorMsg = pcall(obfuscator.obfuscate, testJson, ktoObj, mask)
        lu.assertEquals( errorMsg, './///src/obfuscator.lua:53: Expected value but found unexpected end of string at character 23')
    end
-- class TestObfuscate

os.exit( lu.LuaUnit:run() )