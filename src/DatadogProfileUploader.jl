module DatadogProfileUploader

import HTTP

using Dates
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
    start::DateTime
    finish::DateTime
    type::String # "heap" or "cpu"
    proto_path::String
end

function upload_file_on_disk(config, path)
    start = now()
    finish = now() + Dates.Minute(1)
    upload(config, SerializedProfile(start, finish, "cpu", path))
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
        # "start" => Dates.format(profile.start, ExpectedDateFormat),
        "start" => "2022-10-27T23:54:24+02:00",
        # "end" => Dates.format(profile.finish, ExpectedDateFormat),
        "end" => "2022-10-27T23:55:24+02:00",
        
        "tags[]" => "runtime:go",
        "tags[]" => "service:julia-sorter",
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
