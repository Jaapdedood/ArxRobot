/*Changes by Maurice Rice Jan 15, 2012
** Converted to AS3
** Updated default data array to reflect  WMM2010 model.
** Original notices included unchanged below
*/
/*  class Magfield.java */

/* Module to calculate magnetic variation and field given position,
**               altitude, and date
** Implements the NIMA (formerly DMA) WMM and IGRF models
**
**    http://www.nima.mil/GandG/ngdc-wmm2000.html
**    For WMM2000 coefficients:
**    ftp://ftp.ngdc.noaa.gov/Solid_Earth/Mainfld_Mag/DoD_Model/wmm.cof
**    For IGRF/DGRF coefficients:
**    http://swdcdb.kugi.kyoto-u.ac.jp/igrf/coef/igrfall.d
**
** Copyright (C) 2000  Edward A Williams <Ed_Williams@compuserve.com>
**
**  The routine uses a spherical harmonic expansion of the magnetic
** potential up to twelfth order, together with its time variation, as
** described in Chapter 4 of "Geomagnetism, Vol 1, Ed. J.A.Jacobs,
** Academic Press (London 1987)". The program first converts geodetic
** coordinates (lat/long on elliptic earth and altitude) to spherical
** geocentric (spherical lat/long and radius) coordinates. Using this,
** the spherical (B_r, B_theta, B_phi) magnetic field components are
** computed from the model. These are finally referred to surface (X, Y,
** Z) coordinates.
**
**   Fields are accurate to better than 200nT, variation and dip to
** better than 0.5 degrees, with the exception of the declination near
** the magnetic poles (where it is ill-defined) where the error may reach
** 4 degrees or more.
**
**   Variation is undefined at both the geographic and
** magnetic poles, even though the field itself is well-behaved. To
** avoid the routine blowing up, latitude entries corresponding to
** the geographic poles are slightly offset. At the magnetic poles,
** the routine returns zero variation.
**
** HISTORY
** Adapted from EAW Excel 3.0 version 3/27/94 EAW
** Recoded in C++ by Starry Chan
** WMM95 added and rearranged in ANSI-C EAW 7/9/95
** Put shell around program and made Borland & GCC compatible EAW 11/22/95
** IGRF95 added 2/96 EAW
** WMM2000 IGR2000 added 2/00 EAW
** Released under GPL  3/26/00 EAW
** Adaptions and modifications for the SimGear project  3/27/2000 CLO
** Removed all pow() calls and made static roots[][] arrays to
** save many sqrt() calls on subsequent invocations
** 3/28/2000  Norman Vine -- nhv@yahoo.com
** Put in some bullet-proofing to handle magnetic and geographic poles.
** 3/28/2000 EAW
** Converted to Java class
** 12/6/2000 Reece Robinson
**
** This program is free software; you can redistribute it and/or
** modify it under the terms of the GNU General Public License as
** published by the Free Software Foundation; either version 2 of the
** License, or (at your option) any later version.
**
** This program is distributed in the hope that it will be useful, but
** WITHOUT ANY WARRANTY; without even the implied warranty of
** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
** General Public License for more details.
**
** You should have received a copy of the GNU General Public License
** along with this program; if not, write to the Free Software
** Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
**
*/

package com.arxterra.utils
{
	public class GeoMagField
	{
		public function GeoMagField()
		{
			loadInput();
		}
		
		
		private static var input:Array = [
			"WMM2010  2010.00 12 12  0 2010.00 2015.00   -1.0  600.0          WMM2010   0 ",
			"1  0  -29496.6       0.0      11.6       0.0                        WMM2010   1",
			"1  1   -1586.3    4944.4      16.5     -25.9                        WMM2010   2",
			"2  0   -2396.6       0.0     -12.1       0.0                        WMM2010   3",
			"2  1    3026.1   -2707.7      -4.4     -22.5                        WMM2010   4",
			"2  2    1668.6    -576.1       1.9     -11.8                        WMM2010   5",
			"3  0    1340.1       0.0       0.4       0.0                        WMM2010   6",
			"3  1   -2326.2    -160.2      -4.1       7.3                        WMM2010   7",
			"3  2    1231.9     251.9      -2.9      -3.9                        WMM2010   8",
			"3  3     634.0    -536.6      -7.7      -2.6                        WMM2010   9",
			"4  0     912.6       0.0      -1.8       0.0                        WMM2010  10",
			"4  1     808.9     286.4       2.3       1.1                        WMM2010  11",
			"4  2     166.7    -211.2      -8.7       2.7                        WMM2010  12",
			"4  3    -357.1     164.3       4.6       3.9                        WMM2010  13",
			"4  4      89.4    -309.1      -2.1      -0.8                        WMM2010  14",
			"5  0    -230.9       0.0      -1.0       0.0                        WMM2010  15",
			"5  1     357.2      44.6       0.6       0.4                        WMM2010  16",
			"5  2     200.3     188.9      -1.8       1.8                        WMM2010  17",
			"5  3    -141.1    -118.2      -1.0       1.2                        WMM2010  18",
			"5  4    -163.0       0.0       0.9       4.0                        WMM2010  19",
			"5  5      -7.8     100.9       1.0      -0.6                        WMM2010  20",
			"6  0      72.8       0.0      -0.2       0.0                        WMM2010  21",
			"6  1      68.6     -20.8      -0.2      -0.2                        WMM2010  22",
			"6  2      76.0      44.1      -0.1      -2.1                        WMM2010  23",
			"6  3    -141.4      61.5       2.0      -0.4                        WMM2010  24",
			"6  4     -22.8     -66.3      -1.7      -0.6                        WMM2010  25",
			"6  5      13.2       3.1      -0.3       0.5                        WMM2010  26",
			"6  6     -77.9      55.0       1.7       0.9                        WMM2010  27",
			"7  0      80.5       0.0       0.1       0.0                        WMM2010  28",
			"7  1     -75.1     -57.9      -0.1       0.7                        WMM2010  29",
			"7  2      -4.7     -21.1      -0.6       0.3                        WMM2010  30",
			"7  3      45.3       6.5       1.3      -0.1                        WMM2010  31",
			"7  4      13.9      24.9       0.4      -0.1                        WMM2010  32",
			"7  5      10.4       7.0       0.3      -0.8                        WMM2010  33",
			"7  6       1.7     -27.7      -0.7      -0.3                        WMM2010  34",
			"7  7       4.9      -3.3       0.6       0.3                        WMM2010  35",
			"8  0      24.4       0.0      -0.1       0.0                        WMM2010  36",
			"8  1       8.1      11.0       0.1      -0.1                        WMM2010  37",
			"8  2     -14.5     -20.0      -0.6       0.2                        WMM2010  38",
			"8  3      -5.6      11.9       0.2       0.4                        WMM2010  39",
			"8  4     -19.3     -17.4      -0.2       0.4                        WMM2010  40",
			"8  5      11.5      16.7       0.3       0.1                        WMM2010  41",
			"8  6      10.9       7.0       0.3      -0.1                        WMM2010  42",
			"8  7     -14.1     -10.8      -0.6       0.4                        WMM2010  43",
			"8  8      -3.7       1.7       0.2       0.3                        WMM2010  44",
			"9  0       5.4       0.0      -0.0       0.0                        WMM2010  45",
			"9  1       9.4     -20.5      -0.1      -0.0                        WMM2010  46",
			"9  2       3.4      11.5       0.0      -0.2                        WMM2010  47",
			"9  3      -5.2      12.8       0.3       0.0                        WMM2010  48",
			"9  4       3.1      -7.2      -0.4      -0.1                        WMM2010  49",
			"9  5     -12.4      -7.4      -0.3       0.1                        WMM2010  50",
			"9  6      -0.7       8.0       0.1      -0.0                        WMM2010  51",
			"9  7       8.4       2.1      -0.1      -0.2                        WMM2010  52",
			"9  8      -8.5      -6.1      -0.4       0.3                        WMM2010  53",
			"9  9     -10.1       7.0      -0.2       0.2                        WMM2010  54",
			"10  0      -2.0       0.0       0.0       0.0                        WMM2010  55",
			"10  1      -6.3       2.8      -0.0       0.1                        WMM2010  56",
			"10  2       0.9      -0.1      -0.1      -0.1                        WMM2010  57",
			"10  3      -1.1       4.7       0.2       0.0                        WMM2010  58",
			"10  4      -0.2       4.4      -0.0      -0.1                        WMM2010  59",
			"10  5       2.5      -7.2      -0.1      -0.1                        WMM2010  60",
			"10  6      -0.3      -1.0      -0.2      -0.0                        WMM2010  61",
			"10  7       2.2      -3.9       0.0      -0.1                        WMM2010  62",
			"10  8       3.1      -2.0      -0.1      -0.2                        WMM2010  63",
			"10  9      -1.0      -2.0      -0.2       0.0                        WMM2010  64",
			"10 10      -2.8      -8.3      -0.2      -0.1                        WMM2010  65",
			"11  0       3.0       0.0       0.0       0.0                        WMM2010  66",
			"11  1      -1.5       0.2       0.0      -0.0                        WMM2010  67",
			"11  2      -2.1       1.7      -0.0       0.1                        WMM2010  68",
			"11  3       1.7      -0.6       0.1       0.0                        WMM2010  69",
			"11  4      -0.5      -1.8      -0.0       0.1                        WMM2010  70",
			"11  5       0.5       0.9       0.0       0.0                        WMM2010  71",
			"11  6      -0.8      -0.4      -0.0       0.1                        WMM2010  72",
			"11  7       0.4      -2.5      -0.0       0.0                        WMM2010  73",
			"11  8       1.8      -1.3      -0.0      -0.1                        WMM2010  74",
			"11  9       0.1      -2.1       0.0      -0.1                        WMM2010  75",
			"11 10       0.7      -1.9      -0.1      -0.0                        WMM2010  76",
			"11 11       3.8      -1.8      -0.0      -0.1                        WMM2010  77",
			"12  0      -2.2       0.0      -0.0       0.0                        WMM2010  78",
			"12  1      -0.2      -0.9       0.0      -0.0                        WMM2010  79",
			"12  2       0.3       0.3       0.1       0.0                        WMM2010  80",
			"12  3       1.0       2.1       0.1      -0.0                        WMM2010  81",
			"12  4      -0.6      -2.5      -0.1       0.0                        WMM2010  82",
			"12  5       0.9       0.5      -0.0      -0.0                        WMM2010  83",
			"12  6      -0.1       0.6       0.0       0.1                        WMM2010  84",
			"12  7       0.5      -0.0       0.0       0.0                        WMM2010  85",
			"12  8      -0.4       0.1      -0.0       0.0                        WMM2010  86",
			"12  9      -0.4       0.3       0.0      -0.0                        WMM2010  87",
			"12 10       0.2      -0.9       0.0      -0.0                        WMM2010  88",
			"12 11      -0.8      -0.2      -0.1       0.0                        WMM2010  89",
			"12 12       0.0       0.9       0.1       0.0                        WMM2010  90"
		];
		/**
		 *  http://www.ngdc.noaa.gov/geomag/WMM/soft.shtml
		 *  Coefficient file (WMM.COF) being used
		 **/
		public var strModel:String = "";
		
		/**
		 *	Geodetic altitude in km. An input,
		 *	but set to zero in this class.  Changed
		 *	back to an input in version 5.  If not specified,
		 *	then is 0.
		 */
		private var alt:Number = 0;
		/**
		 *	Geodetic latitude in deg.  An input.
		 */
		private var glat:Number = 0;
		/**
		 *	Geodetic longitude in deg.  An input.
		 */
		private var glon:Number = 0;
		/**
		 *	Time is decimal years.  An input
		 */
		private var time:Number = 0;
		/**
		 *	Geomagnetic declination in deg.
		 *	East is positive, West is negative.
		 *	(The negative of variation.)
		 */
		private var dec:Number = 0;
		/**
		 *	Geomagnetic inclination in deg.
		 *	Down is positive, up is negative.
		 */
		private var dip:Number = 0;
		/**
		 *	Geomagnetic total intensity, in nano Teslas.
		 */
		private var ti:Number = 0;
		/**
		 *	Geomagnetic grid variation, referenced to
		 *	grid North.  Not calculated or output in version 5.0.
		 */
		//private double gv = 0;
		/**
		 *	The maximum number of degrees of the spherical harmonic model.
		 */
		private var maxdeg:int = 12;
		/**
		 *	The maximum order of spherical harmonic model.
		 */
		private var maxord:int;
		private var n:int,m:int,j:int,D1:int,D2:int,D3:int,D4:int; //icomp,i,
		//private boolean bOutDated = false;
		/**
		 *	An error flag to set whether the input file with the fit
		 *	coefficients was found, and read OK.  If the input file is not found,
		 *	or the data wasn't read,
		 *	it is true, and the declination, etc. is always returned as 0.0.
		 *	In version 5, this is always false, so that a calculation is always
		 *	performed.
		 */
		private var inputError:Boolean = false;
		
		/**	Added in version 5.  In earlier versions the date for the calculation was held as a
		 *  constant.  In version 5, if no date is specified in the calulation, this date is used
		 * 	by default.
		 */
		private var currentFixedDate:Number = 2011;
		
		/**	Added in version 5.  In earlier versions the altitude for the calculation was held as a
		 *  constant at 0.  In version 5, if no altitude is specified in the calculation, this
		 * 	altitude is used by default.
		 */
		private var currentFixedAltitude:Number = 0;
		
		/**
		 *	The gauss coefficients of main geomagnetic model (nt).
		 */
		//private double c[][] = new double[13][13];
		private var c:Vector.<Vector.<Number>> =  initVector(13,13);
		/**
		 *	The gauss coefficients of secular geomagnetic model (nt/yr).
		 */
		//private double cd[][] = new double[13][13];
		private var cd:Vector.<Vector.<Number>> =  initVector(13,13);
		/**
		 *	The time adjusted geomagnetic gauss coefficients (nt).
		 */
		//private double tc[][] = new double[13][13];
		private var tc:Vector.<Vector.<Number>> =  initVector(13,13);
		/**
		 *	The theta derivative of p(n,m) (unnormalized).
		 */
		//private double dp[][] = new double[13][13];
		private var dp:Vector.<Vector.<Number>> =  initVector(13,13);
		/**
		 *	The Schmidt normalization factors.
		 */
		//private double snorm[] = new double[169];
		private var snorm:Vector.<Number> = new Vector.<Number>(169);
		/**
		 *	The sine of (m*spherical coord. longitude).
		 */
		//private double sp[] = new double[13];
		private var sp:Vector.<Number> = new Vector.<Number>(13);
		/**
		 *	The cosine of (m*spherical coord. longitude).
		 */
		//private double cp[] = new double[13];
		//private double fn[] = new double[13];
		//private double fm[] = new double[13];
		private var cp:Vector.<Number> = new Vector.<Number>(13);
		private var fn:Vector.<Number> = new Vector.<Number>(13);
		private var fm:Vector.<Number> = new Vector.<Number>(13);
		
		/**
		 *	The associated legendre polynomials for m=1 (unnormalized).
		 */
		//private double pp[] = new double[13];
		//private double k[][] = new double[13][13];
		private var pp:Vector.<Number> =  new Vector.<Number>(13);
		private var k:Vector.<Vector.<Number>> =  initVector(13,13);
		
		
		public var validUntil:String = "";
		public var epoch:Number = 0;
		
		private var pi:Number,dtr:Number,gnm:Number,hnm:Number,dgnm:Number,dhnm:Number,flnmj:Number,otime:Number,oalt:Number,
		olat:Number,olon:Number,d:Number,rlon:Number,rlat:Number,srlon:Number,srlat:Number,crlon:Number,crlat:Number,srlat2:Number,
		crlat2:Number,q:Number,q1:Number,q2:Number,ct:Number,st:Number,r2:Number,r:Number,dt:Number,ca:Number,sa:Number,aor:Number,ar:Number,br:Number,bt:Number,bp:Number,bpp:Number,
		par:Number,temp1:Number,temp2:Number,parp:Number,bx:Number,by:Number,bz:Number,bh:Number, a:Number,b:Number,re:Number ,a2:Number,b2:Number,c2:Number,a4:Number,b4:Number, c4:Number;
		//Number
		
		
		
		private function initVector( size:int, col:int ): Vector.<Vector.<Number>> {
			var ret:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>();
			var n:int;
			var i:int;
			for ( n=0; n<size;n++ ){
				ret[n] = new Vector.<Number>();
				for (i=0; i<col; i++) {
					ret[n][i]=0.0;
				}
			}
			return ret;
		}
		
		
		private function loadInput():void{
			
			glat = 0;
			glon = 0;
			//bOutDated = false;
			//String strModel = new String();
			//String strFile = new String("WMM.COF");
			//		String strFile = new String("wmm-95.dat");
			
			// INITIALIZE CONSTANTS
			maxord = maxdeg;
			sp[0] = 0.0;
			cp[0] = snorm[0] = pp[0] = 1.0;
			dp[0][0] = 0.0;
			/**
			 *	Semi-major axis of WGS-84 ellipsoid, in km.
			 */
			a = 6378.137;
			/**
			 *	Semi-minor axis of WGS-84 ellipsoid, in km.
			 */
			b = 6356.7523142;
			/**
			 *	Mean radius of IAU-66 ellipsoid, in km.
			 */
			re = 6371.2;
			a2 = a * a;
			b2 = b * b;
			c2 = a2 - b2;
			a4 = a2 * a2;
			b4 = b2 * b2;
			c4 = a4 - b4;
			
			
			var i:int = 0;
			var line:Array = String(input[0]).split( / +/ );;
			
			c[0][0] = 0.0;
			cd[0][0] = 0.0;
			
			
			epoch =  line[1];
			//trace("Epoch is: " + epoch);
			strModel = line[0];
			//trace("Model is: " + strModel);
			//trace("Valid to: " + line[6]);
			validUntil = line[6];
			
			for( i=1; i<input.length; i++)
			{
				line = String(input[i]).split( / +/ );
				n = line[0];
				m = line[1];
				gnm = line[2];
				hnm = line[3];
				dgnm = line[4];
				dhnm = line[5];
				
				if (m <= n)	{
					c[m][n] = gnm;
					cd[m][n] = dgnm;
					
					if (m != 0)
					{
						c[n][m-1] = hnm;
						cd[n][m-1] = dhnm;
					}
				}
				
			}
			
			// CONVERT SCHMIDT NORMALIZED GAUSS COEFFICIENTS TO UNNORMALIZED
			snorm[0] = 1.0;
			for (n = 1; n <= maxord; n++){
				
				snorm[n] = snorm[n - 1] * (2 * n - 1) / n;
				j = 2;
				
				for(m = 0,D1 = 1,D2 = (n - m + D1) / D1; D2 > 0; D2--, m += D1){
					k[m][n] =  (((n - 1) * (n - 1))-(m * m))/ ((2 * n-1)*(2*n-3));
					if(m > 0){
						flnmj = ((n - m + 1) * j) /  (n + m);
						snorm[n + m * 13] = snorm[n + (m -1 ) * 13] * Math.sqrt(flnmj);
						j = 1;
						c[n][m-1] = snorm[n + m * 13] * c[n][m-1];
						cd[n][m-1] = snorm[n + m * 13] * cd[n][m-1];
					}
					c[m][n] = snorm[n + m * 13] * c[m][n];
					cd[m][n] = snorm[n + m * 13] * cd[m][n];
				}	//for(m...)
				
				fn[n] = (n+1);
				fm[n] = n;
				
			}	//for(n...)
			
			k[1][1] = 0.0;
			
			otime = oalt = olat = olon = -1000.0;
			
		}
		
		/**     PURPOSE:  THIS ROUTINE COMPUTES THE DECLINATION (DEC),
		 *               INCLINATION (DIP), TOTAL INTENSITY (TI) AND
		 *               GRID VARIATION (GV - POLAR REGIONS ONLY, REFERENCED
		 *               TO GRID NORTH OF POLAR STEREOGRAPHIC PROJECTION) OF
		 *               THE EARTH'S MAGNETIC FIELD IN GEODETIC COORDINATES
		 *               FROM THE COEFFICIENTS OF THE CURRENT OFFICIAL
		 *               DEPARTMENT OF DEFENSE (DOD) SPHERICAL HARMONIC WORLD
		 *               MAGNETIC MODEL (WMM-2000).  THE WMM SERIES OF MODELS IS
		 *               UPDATED EVERY 5 YEARS ON JANUARY 1'ST OF THOSE YEARS
		 *               WHICH ARE DIVISIBLE BY 5 (I.E. 1980, 1985, 1990 ETC.)
		 *               BY THE NAVAL OCEANOGRAPHIC OFFICE IN COOPERATION
		 *               WITH THE BRITISH GEOLOGICAL SURVEY (BGS).  THE MODEL
		 *               IS BASED ON GEOMAGNETIC SURVEY MEASUREMENTS FROM
		 *               AIRCRAFT, SATELLITE AND GEOMAGNETIC OBSERVATORIES.
		 *
		 *
		 *
		 *     ACCURACY:  IN OCEAN AREAS AT THE EARTH'S SURFACE OVER THE
		 *                ENTIRE 5 YEAR LIFE OF A DEGREE AND ORDER 12
		 *                SPHERICAL HARMONIC MODEL SUCH AS WMM-95, THE ESTIMATED
		 *                RMS ERRORS FOR THE VARIOUS MAGENTIC COMPONENTS ARE:
		 *
		 *                DEC  -   0.5 Degrees
		 *                DIP  -   0.5 Degrees
		 *                TI   - 280.0 nanoTeslas (nT)
		 *                GV   -   0.5 Degrees
		 *
		 *                OTHER MAGNETIC COMPONENTS THAT CAN BE DERIVED FROM
		 *                THESE FOUR BY SIMPLE TRIGONOMETRIC RELATIONS WILL
		 *                HAVE THE FOLLOWING APPROXIMATE ERRORS OVER OCEAN AREAS:
		 *
		 *                X    - 140 nT (North)
		 *                Y    - 140 nT (East)
		 *                Z    - 200 nT (Vertical)  Positive is down
		 *                H    - 200 nT (Horizontal)
		 *
		 *                OVER LAND THE RMS ERRORS ARE EXPECTED TO BE SOMEWHAT
		 *                HIGHER, ALTHOUGH THE RMS ERRORS FOR DEC, DIP AND GV
		 *                ARE STILL ESTIMATED TO BE LESS THAN 0.5 DEGREE, FOR
		 *                THE ENTIRE 5-YEAR LIFE OF THE MODEL AT THE EARTH's
		 *                SURFACE.  THE OTHER COMPONENT ERRORS OVER LAND ARE
		 *                MORE DIFFICULT TO ESTIMATE AND SO ARE NOT GIVEN.
		 *
		 *                THE ACCURACY AT ANY GIVEN TIME OF ALL FOUR
		 *                GEOMAGNETIC PARAMETERS DEPENDS ON THE GEOMAGNETIC
		 *                LATITUDE.  THE ERRORS ARE LEAST AT THE EQUATOR AND
		 *                GREATEST AT THE MAGNETIC POLES.
		 *
		 *                IT IS VERY IMPORTANT TO NOTE THAT A DEGREE AND
		 *                ORDER 12 MODEL, SUCH AS WMM-2000 DESCRIBES ONLY
		 *                THE LONG WAVELENGTH SPATIAL MAGNETIC FLUCTUATIONS
		 *                DUE TO EARTH'S CORE.  NOT INCLUDED IN THE WMM SERIES
		 *                MODELS ARE INTERMEDIATE AND SHORT WAVELENGTH
		 *                SPATIAL FLUCTUATIONS OF THE GEOMAGNETIC FIELD
		 *                WHICH ORIGINATE IN THE EARTH'S MANTLE AND CRUST.
		 *                CONSEQUENTLY, ISOLATED ANGULAR ERRORS AT VARIOUS
		 *                POSITIONS ON THE SURFACE (PRIMARILY OVER LAND, IN
		 *                CONTINENTAL MARGINS AND OVER OCEANIC SEAMOUNTS,
		 *                RIDGES AND TRENCHES) OF SEVERAL DEGREES MAY BE
		 *                EXPECTED. ALSO NOT INCLUDED IN THE MODEL ARE
		 *                NONSECULAR TEMPORAL FLUCTUATIONS OF THE GEOMAGNETIC
		 *                FIELD OF MAGNETOSPHERIC AND IONOSPHERIC ORIGIN.
		 *                DURING MAGNETIC STORMS, TEMPORAL FLUCTUATIONS CAN
		 *                CAUSE SUBSTANTIAL DEVIATIONS OF THE GEOMAGNETIC
		 *                FIELD FROM MODEL VALUES.  IN ARCTIC AND ANTARCTIC
		 *                REGIONS, AS WELL AS IN EQUATORIAL REGIONS, DEVIATIONS
		 *                FROM MODEL VALUES ARE BOTH FREQUENT AND PERSISTENT.
		 *
		 *                IF THE REQUIRED DECLINATION ACCURACY IS MORE
		 *                STRINGENT THAN THE WMM SERIES OF MODELS PROVIDE, THEN
		 *                THE USER IS ADVISED TO REQUEST SPECIAL (REGIONAL OR
		 *                LOCAL) SURVEYS BE PERFORMED AND MODELS PREPARED BY
		 *                THE USGS, WHICH OPERATES THE US GEOMAGNETIC
		 *                OBSERVATORIES.  REQUESTS OF THIS NATURE SHOULD
		 *                BE MADE THROUGH NIMA AT THE ADDRESS ABOVE.
		 *
		 *
		 *
		 *     NOTE:  THIS VERSION OF GEOMAG USES THE WMM-2005 GEOMAGNETIC
		 *            MODEL REFERENCED TO THE WGS-84 GRAVITY MODEL ELLIPSOID
		 *
		 *	@param	fLat			The latitude in decimal degrees.
		 *	@param	fLon			The longitude in decimal degrees.
		 *	@param	year			The date as a decimal year.
		 *	@param	altitude		The altitude in kilometers.
		 */
		//	void CalcGeoMag(double fLat, double fLon, double fAlt, double fTime, boolean bCurrent)
		private function calcGeoMag( fLat:Number,  fLon:Number, year:Number, altitude:Number):void
		{
			glat =  fLat;
			glon =  fLon;
			//alt = fAlt;
			alt = altitude;
			//time = fTime;
			/**
			 *	The date in decimal years for calculating the magnetic field components.
			 */
			time = year;
			
			dt = time - epoch;
			//if (otime < 0.0 && (dt < 0.0 || dt > 5.0))
			//		if(bCurrent){
			//			if (dt < 0.0 || dt > 5.0)
			//				bOutDated = true;
			//			else
			//				bOutDated = false;
			//		}
			
			pi =  3.14159265359;		// could be replaced by Math.PI
			dtr = (pi/180.0);
			rlon = glon * dtr;
			rlat = glat * dtr;
			srlon = Math.sin(rlon);
			srlat = Math.sin(rlat);
			crlon = Math.cos(rlon);
			crlat = Math.cos(rlat);
			srlat2 = srlat * srlat;
			crlat2 = crlat * crlat;
			sp[1] = srlon;
			cp[1] = crlon;
			
			// CONVERT FROM GEODETIC COORDS. TO SPHERICAL COORDS.
			if (alt != oalt || glat != olat){
				q = Math.sqrt(a2 - c2 * srlat2);
				q1 = alt * q;
				q2 = ((q1 + a2) / (q1 + b2)) * ((q1 + a2) / (q1 + b2));
				ct = srlat / Math.sqrt(q2 * crlat2 + srlat2);
				st = Math.sqrt(1.0 - (ct * ct));
				r2 = ((alt*alt) + 2.0 * q1 + (a4 - c4 * srlat2) / (q * q));
				r = Math.sqrt(r2);
				d = Math.sqrt(a2 * crlat2 + b2 * srlat2);
				ca = (alt + d) / r;
				sa = c2 * crlat * srlat / (r * d);
			}
			if (glon != olon){
				for (m = 2; m <= maxord; m++){
					sp[m] = sp[1] * cp[m-1] + cp[1] * sp[m-1];
					cp[m] = cp[1] * cp[m-1] - sp[1] * sp[m-1];
				}
			}
			aor = re / r;
			ar = aor * aor;
			br = bt = bp = bpp = 0.0;
			
			for(n = 1; n <= maxord; n++){
				ar = ar * aor;
				for (m = 0,D3 = 1,D4 = (n + m + D3) / D3; D4 > 0; D4--,m += D3){
					
					//COMPUTE UNNORMALIZED ASSOCIATED LEGENDRE POLYNOMIALS
					//AND DERIVATIVES VIA RECURSION RELATIONS
					if(alt != oalt || glat != olat){
						if(n == m){
							snorm[n + m * 13] = st * snorm[n - 1 + (m - 1) * 13];
							dp[m][n] = st * dp[m-1][n-1]+ ct* snorm[n - 1 + (m - 1) * 13];
						}
						if(n == 1 && m == 0){
							snorm[n + m * 13] = ct * snorm[n - 1 + m * 13];
							dp[m][n] = ct * dp[m][n - 1] - st * snorm[n - 1 + m * 13];
						}
						if(n > 1 && n != m){
							if(m > n - 2)
								snorm[n - 2 + m * 13] = 0.0;
							if(m > n - 2)
								dp[m][n - 2] = 0.0;
							snorm[n + m * 13] = ct * snorm[n - 1 + m * 13] - k[m][n] * snorm[n - 2 + m * 13];
							dp[m][n] = ct * dp[m][n - 1] - st * snorm[n - 1 + m * 13] - k[m][n] * dp[m][n - 2];
						}
					}
					
					//TIME ADJUST THE GAUSS COEFFICIENTS
					
					if(time != otime){
						tc[m][n] = c[m][n] + dt * cd[m][n];
						
						if(m != 0)
							tc[n][m - 1] = c[n][m - 1]+ dt * cd[n][m - 1];
					}
					
					//ACCUMULATE TERMS OF THE SPHERICAL HARMONIC EXPANSIONS
					
					par = ar * snorm[ n + m * 13];
					if(m == 0){
						temp1 = tc[m][n] * cp[m];
						temp2 = tc[m][n] * sp[m];
					}
					else{
						temp1 = tc[m][n] * cp[m] + tc[n][m - 1] * sp[m];
						temp2 = tc[m][n] * sp[m] - tc[n][m - 1] * cp[m];
					}
					
					bt = bt - ar * temp1 * dp[m][n];
					bp += (fm[m] * temp2 * par);
					br += (fn[n] * temp1 * par);
					
					//SPECIAL CASE:  NORTH/SOUTH GEOGRAPHIC POLES
					
					if(st == 0.0 && m == 1){
						if(n == 1)
							pp[n] = pp[n - 1];
						else
							pp[n] = ct * pp[n - 1] - k[m][n] * pp[n - 2];
						parp = ar * pp[n];
						bpp += (fm[m] * temp2 * parp);
					}
					
				}	//for(m...)
				
			}	//for(n...)
			
			
			if(st == 0.0)
				bp = bpp;
			else
				bp /= st;
			
			//ROTATE MAGNETIC VECTOR COMPONENTS FROM SPHERICAL TO
			//GEODETIC COORDINATES
			// bx must be the east-west field component
			// by must be the north-south field component
			// bx must be the vertical field component.
			bx = -bt * ca - br * sa;
			by = bp;
			bz = bt * sa - br * ca;
			
			//COMPUTE DECLINATION (DEC), INCLINATION (DIP) AND
			//TOTAL INTENSITY (TI)
			
			bh = Math.sqrt((bx * bx)+(by * by));
			ti = Math.sqrt((bh * bh)+(bz * bz));
			//	Calculate the declination.
			dec = (Math.atan2(by, bx) / dtr);
			//System.out.println( "Dec is: " + dec );
			dip = (Math.atan2(bz, bh) / dtr);
			
			//	This is the variation for grid navigation.
			//	Not used at this time.  See St. Ledger for explanation.
			//COMPUTE MAGNETIC GRID VARIATION IF THE CURRENT
			//GEODETIC POSITION IS IN THE ARCTIC OR ANTARCTIC
			//(I.E. GLAT > +55 DEGREES OR GLAT < -55 DEGREES)
			// Grid North is referenced to the 0 Meridian of a polar
			// stereographic projection.
			
			//OTHERWISE, SET MAGNETIC GRID VARIATION TO -999.0
			/*
			gv = -999.0;
			if (Math.abs(glat) >= 55.){
			if (glat > 0.0 && glon >= 0.0)
			gv = dec-glon;
			if (glat > 0.0 && glon < 0.0)
			gv = dec + Math.abs(glon);
			if (glat < 0.0 && glon >= 0.0)
			gv = dec+glon;
			if (glat < 0.0 && glon < 0.0)
			gv = dec - Math.abs(glon);
			if (gv > +180.0)
			gv -= 360.0;
			if (gv < -180.0)
			gv += 360.0;
			}
			*/
			otime = time;
			oalt = alt;
			olat = glat;
			olon = glon;
			
		}
		
		/**
		 *	Returns the declination from the 2005 Department of
		 *	Defense geomagnetic model and data, in degrees.  The
		 *	magnetic heading + declination = true heading.
		 * 	(True heading + variation = magnetic heading.)
		 *
		 *	@param	dlat		Latitude in decimal degrees.
		 *	@param 	dlong	Longitude in decimal degrees.
		 */
		public function getDeclination( dlat:Number, dlong:Number ):Number
		{
			if( inputError)
			{
				return 0.0;
			}
			else
			{
				calcGeoMag( dlat, dlong, currentFixedDate, currentFixedAltitude );
				return  dec;
			}
		}
		
		
	}
}