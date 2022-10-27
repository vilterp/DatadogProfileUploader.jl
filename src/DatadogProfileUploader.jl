module DatadogProfileUploader

import HTTP

using Dates
using TimeZones
using Profile
using PProf

Base.@kwdef struct DDConfig
    host::String = "intake.profile.datadoghq.com"
    port::Int = 443
    protocol::String = "https"
    api_key::String
    hostname::String
end

struct SerializedProfile
    # API expects zoned datetimes
    start::ZonedDateTime
    finish::ZonedDateTime
    type::String # "heap" or "cpu"
    proto_path::String
end

function upload_file_on_disk(config, path)
    local_now = now(localzone())
    start = local_now
    finish = local_now + Dates.Minute(1)
    upload(config, SerializedProfile(start, finish, "cpu", path))
end

function profile_and_upload(config, f)
    Profile.clear()
    start = now(localzone())
    Profile.@profile f()
    finish = now(localzone())
    
    path = "profile-$(now()).pb.gz"
    try
        pprof(; web=false, out=path)
        upload(config, SerializedProfile(start, finish, "cpu", path))
    finally
        rm(path)
    end
end

function upload(config::DDConfig, profile::SerializedProfile)
    headers = [
        "DD-API-KEY" => config.api_key,
    ]
    # do HTTP request
    profile_name = "$(profile.type).pprof"
    parts = Pair{String,Any}[
        "version" => "3",
        "family" => "go",
        "start" => string(profile.start),
        "end" => string(profile.finish),
        
        "tags[]" => "runtime:go",
        "tags[]" => "service:julia-sorter-2",
        "tags[]" => "env:example",
        
        "data[$profile_name]" => HTTP.Multipart(
            "pprof-data",
            open(profile.proto_path), # proto
            "application/octet-stream"
        ),
    ]
    body = HTTP.Form(parts)
    url = "$(config.protocol)://$(config.host):$(config.port)/v1/input"
    println("posting to $url")
    resp = HTTP.post(url, headers, body)
    println("got response ", resp)
end

end # module
