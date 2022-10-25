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
    Profile.clear()
    start = now()
    Profile.@profile f()
    finish = now()
    
    path = "profile-$(now()).pb.gz"
    try
        pprof(; web=false, out=path)
        upload(config, SerializedProfile(start, finish, "cpu", path))
    finally
        rm(path)
    end
end

const ExpectedDateFormat = DateFormat("yyyy-mm-dd\\THH:MM:SSZ")

function upload(config::DDConfig, profile::SerializedProfile)
    headers = [
        "DD-API-KEY" => config.api_key,
    ]
    # do HTTP request
    profile_name = "$(profile.type).pprof"
    parts = Pair{String,Any}[
        "version" => "3",
        "family" => "go",
        "start" => Dates.format(profile.start, ExpectedDateFormat),
        "end" => Dates.format(profile.finish, ExpectedDateFormat),
        
        "tags[]" => "host:$(config.hostname)",
        "tags[]" => "runtime:go",
        "tags[]" => "pid:60677",
        "tags[]" => "profiler_version:v1.36.0",
        "tags[]" => "runtime_version:1.18.3",
        "tags[]" => "runtime_compiler:gc",
        "tags[]" => "runtime_arch:amd64",
        "tags[]" => "runtime_os:darwin",
        "tags[]" => "runtime-id:d9b59eb6-d5f7-4534-ae82-793f29397",
        "tags[]" => "version:1.0",
        "tags[]" => "service:julia-sorter",
        "tags[]" => "env:example",
        
        "data[$profile_name]" => HTTP.Multipart(
            "pprof-data",
            open(profile.proto_path), # proto
            "application/octet-stream"
        ),
    ]
    body = HTTP.Form(parts)
    url = "https://intake.profile.datadoghq.com/v1/input"
    # url = "http://localhost:8126/profiling/v1/input"
    println("posting to $url")
    resp = HTTP.post(url, headers, body)
    println("got response ", resp)
end

end # module
