function PRDCalc(p, att)
    DebugPrint("prd: nominal = " .. p)
    local N = math.floor(1/p)
    local C = 1 - (1-p)^(1/N)
    DebugPrint("prd: c_const = " .. C)

    local final = C * (att)
    DebugPrint("prd: attempt = " .. att)
    DebugPrint("prd: factical = " .. final)

    return RandomFloat(0, 1) < final
end

function PRDCalc_Pct(p, att)
    return PRDCalc(p/100, att)
end