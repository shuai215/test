using CSV,DataFrames,Statistics
function read_data(filepath)
    df=CSV.read(filepath,DataFrame)
    return df
end

function replace_missing!(df)
    for col in eachcol(df)
        replace!(col, missing=>0)
    end
    return nothing
end

function calc_residual_load!(df)
    select!(
        df,
        :,
    [:Wind,:PV,:Load]=>((w,p,l)->l .-p .-w )=>Symbol("Residual Load"),
    )
    return nothing
end

function calc_avg!(df)
    gdf=groupby(df, :Region)
    cdf=combine(gdf,:Load=>mean=>Symbol("Mean Load"),
                    :Wind=>mean=>Symbol("Mean Wind"),
                    :PV=>mean=>Symbol("Mean PV"),
                    Symbol("Residual Load")=>mean=>Symbol("Mean Residual Load")
    
    )
return cdf
end

function sort_by_residual!(df)
    sort!(df,[:Region,Symbol("Residual Load")],rev=true)
end

function get_residual_load(df,country)

    subset(df,:Region=>x->x.==(country))
end

function get_countrywise_residual_load(df)
    new_df=unstack(
        select(df,Not([:Load, :PV ,:Wind])),
    :Region, Symbol("Residual Load"),renamecols=x->Symbol(x,"Residual Load")
    )
    sort!(new_df,[:Year,:Hour])
    return new_df
end

function write_country_residual_load(df,filepath)
    udf=get_countrywise_residual_load(df)
    CSV.write(filepath,udf)
    return nothing
    
end
datafile1=joinpath(@__DIR__,"load_data_1.csv")
writefile1=joinpath(@__DIR__,"write_data_1.csv")

df=read_data(datafile1)
@assert size(df)==(52560,6)

retval=replace_missing!(df)
@assert isapprox(any(ismissing.(df.Wind)),false,atol=1e-1)

retval=calc_residual_load!(df)
avg_df=calc_avg!(df)
retval=sort_by_residual!(df)
 tstcntry="DE"
 subdf =get_residual_load(df,tstcntry)
 reshdf=get_countrywise_residual_load(df)
 retval=write_country_residual_load(df,writefile1)
  read_df=CSV.read(writefile1, DataFrame)
  rm(writefile1,force=true)


using CSV,DataFrames,Makie,CairoMakie,Statistics

function read_data(filepath,country,year)
    df=CSV.read(filepath,DataFrame)
    for col in eachcol(df)
        replace!(col,missing=>0)
    end
    disallowmissing!(df)
    return filter!([:Year,:Hour,:Region]=>(y,h,r)->(y==year)&&(r==country),df,)

end

function plot_3D_data(readpath,country,year,savepath)
    df=read_data(readpath,country,year)
    df_wind=reshape(df.Wind,24,365)
    df_solar=reshape(df.PV,24,365)
    f = Figure(resolution = (800, 450))
    ax1=Axis3(f[1,1],
    title="Wind Generation in country for year",
    xlabel="Hour",
    ylabel="Day",
    zlabel="P in MW",
    protrusions=(100,0,50,50),
    zlabeloffset=75,
    )
    ax2=Axis3(f[1,2],
    title="Wind Generation in country for year",
    xlabel="Hour",
    ylabel="Day",
    zlabel="P in MW",
    protrusions=(100,0,50,50),
    zlabeloffset=75,
    )

    surface!(ax1,1:24,1:365,df_wind,colormap = :inferno,rasterize = 1)
    surface!(ax2,1:24,1:365,df_solar,colormap = :inferno,rasterize = 1)
    save(savepath,f)
end

function plot_layout(readpath,country,year,savepath)
    df=read_data(readpath,country,year)
    df_wind=reshape(df.Wind,24,365)
    df_solar=reshape(df.PV,24,365)
    df_wind_avg=vec(mean(df_wind, dims = 1))
    df_solar_avg=vec(mean(df_solar, dims = 1))
    fig=Figure()
    ax1=Axis(
        fig[2,1],
        xlabel="Day",
        ylabel="Hourly Average in MWh",
    )
    wind_scatter=scatter!(ax1,1:length(df_wind_avg),df_wind_avg,color= :deepskyblue, markersize=5,)
    hlines!(ax1,mean(df_wind_avg),linestyle=:dash,color=:red)
    ax2=Axis(
        fig[3,1],
        xlabel="Day",
        ylabel="Hourly Average in MWh",
    )
    solar_scatter=scatter!(ax2,1:length(df_solar_avg),df_solar_avg,color= :gold, markersize=5,)
    hlines!(ax1,mean(df_solar_avg),linestyle=:dash,color=:red)
    
    mean_scatter=hlines!(ax2,mean(df_solar_avg),linestyle=:dash,color=:red)

    ax1right=Axis(fig[2,2])
    linkyaxes!(ax1,ax1right)
    dw=density!(ax1right,
    df_wind_avg,
    color=:blue,
    direction = :y,
    label="Wind density",)
    hlines!(ax1right,mean(df_wind_avg),linestyle=:dash,color=:red)

    ax2right=Axis(fig[3,2])
    linkyaxes!(ax2,ax2right)
    ds=density!(ax2right,
    df_solar_avg,
    color=:blue,
    direction = :y,
    label="Solar density",)
    hlines!(ax2right,mean(df_solar_avg),linestyle=:dash,color=:red)

    Legend(
        fig[1,1:2],
        [wind_scatter,solar_scatter,mean_scatter,dw,ds],
        ["Wind","Solar","Mean","DensityEstimateWind","DensityEstimate
         Solar"],
       "PowerGenerationin $country for $year",

      orientation=:horizontal,
       tellwidth=true,
    )
    save(savepath,fig)
end

datafile1=joinpath(@__DIR__, "load_data_1.csv")
country1="AT"
year1=2021
country2="DE"
year2=2022

df=read_data(datafile1,country1,year1)
 df=read_data(datafile1,country2,year2)
 country = "AT"
 year = 2021
 mkpath(joinpath(@__DIR__, "results"))
  writefile = joinpath(@__DIR__, "results", "task_5_2_1_$(country)_$(year).pdf")
  plot_3D_data(datafile1, country1, year1, writefile)

  writefile = joinpath(@__DIR__, "results", "task_5_3_1_$(country)_$(year).pdf")
plot_layout(datafile1, country, year, writefile)

  country = "BE"
  year = 2022
  writefile = joinpath(@__DIR__, "results", "task_5_2_1_$(country)_$(year).pdf")
  plot_3D_data(datafile1, country, year, writefile)

   writefile = joinpath(@__DIR__, "results", "task_5_3_1_$(country)_$(year).pdf")
   plot_layout(datafile1, country, year, writefile)
  
