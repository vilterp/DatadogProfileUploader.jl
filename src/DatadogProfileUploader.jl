module DatadogProfileUploader

import HTTP

using Dates
using Profile
using PProf

struct DDConfig
    host::String
    port::Int
    hostname::String
    api_key::String
end

struct SerializedProfile
    start::DateTime
    finish::DateTime
    type::String # "heap" or "cpu"
    proto_path::String
end

function profile_and_upload(config, f)
    start = now()
    Profile.@profile f()
    finish = now()

    path = "profile.pb.gz" # TODO: temp file?
    pprof(; web=false, out=path)
    upload(config, SerializedProfile(start, finish, "cpu", path))
end

function upload(config::DDConfig, profile::SerializedProfile)
    # do HTTP request
    headers = [
        "DD-API-KEY" => config.api_key,
    ]
    name = "$(profile.type).pprof"
    body = HTTP.Form([
        "version" => "3",
        "family" => "go",
        "start" => Dates.format(profile.start, ISODateTimeFormat),
        "end" => Dates.format(profile.finish, ISODateTimeFormat),
        "tags[]" => "host:$(config.hostname)",
        "tags[]" => "runtime:go",
        "tags[]" => "env:example",
        "tags[]" => "service:julia-test", # TODO: parameterize
        "tags[]" => "version:1.0", # TODO: parameterize
        "data[$(name)]" => HTTP.Multipart(
            "pprof-data",
            open(profile.proto_path), # proto
            "application/octet-stream"
        ),
    ])
    url = "http://$(config.host):$(config.port)/profiling/v1/input"
    HTTP.post(url, headers, body)
end

end # module
