Either:

    Grab a copy of the map.tif file from the development s3 bucket 'dave-johnson-miniscale-map-data-o9hylzna' and copy into:

        emergency-alerts-localenv/miniscale-map-data/

...or:

    Generate a new map.tif file:

        Register account on osdatahub.os.uk using your digital cabinet email address.

        Download miniscale zip file (~360mb) to Mac:

        	https://osdatahub.os.uk/data/downloads/open/MiniScale

        Unzip the zip file and copy the following file to a working directory:

        	data/RGB_TIF_compressed/MiniScale_standard_R28.tif

        Run on mac:

    	    brew update
	        brew install gdal

        Run the following shell script to convert download to ESPG:3857:

        	bash emergency-alerts-tooling/scripts/convert_miniscale_to_webmerc.sh MiniScale_standard_R28.tif map.tif

    	    The following warning is safe to ignore:

        	Warning 1: Several coordinate operations are going to be used. Artifacts may appear. You may consider using the -to ALLOW_BALLPARK=NO and/or -to ONLY_BEST=YES transform options, or specify a particular coordinate operation with -ct

For local env:

	Copy map.tif to emergency-alerts-localenv/miniscale-map-data/

	Recreate local stack:
		cd emergency-alerts-localenv
		docker compose down localstack
		docker compose up -d --build localstack

	Hop onto local stack docker server and run:
		awslocal s3 ls s3://local-miniscale-map-data/

	Confirm map.tif has is present (takes a few seconds).

For dev/preview/staging/production:

	Confirm s3://miniscale-map-data-* bucket has been created by terraform.
	Manually copy map.tif to bucket s3://miniscale-map-data-*/
