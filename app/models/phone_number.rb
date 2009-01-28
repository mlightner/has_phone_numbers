# Represents a phone number split into multiple parts:
# * +country_code+ - Uniquely identifiers the country to which the number belongs.
#   This value is based on the E.164 standard (http://en.wikipedia.org/wiki/E.164)
# * +number+ - The subscriber number (10 digits in length)
# * +extension+ - A number that can route to different phones at a location
# 
# This phone number format is biased towards those types found in the United
# States and may need to be adjusted for international support.
class PhoneNumber < ActiveRecord::Base
  belongs_to  :phoneable,
              :polymorphic => true
  
  validates_presence_of     :phoneable_id,
                            :phoneable_type,
                            :country_code,
                            :number

  validates_numericality_of :country_code,
                            :number

  validates_numericality_of :extension,
                            :allow_nil => true

  validates_length_of       :country_code,
                            :in => 1..3

  validates_length_of       :number,
                            :is => 10

  validates_length_of       :extension,
                            :maximum => 10,
                            :allow_nil => true
  
  # Generates a human-readable version of the phone number, based on all of the
  # various parts of the number.
  # 
  # For example,
  # 
  #   phone = PhoneNumber.new(:country_code => '1', :number => '123-456-7890')
  #   phone.display_value     # => "1- 123-456-7890"
  #   phone.extension = "123"
  #   phone.display_value     # => "1- 123-456-7890 ext. 123"
  def display_value
    human_number = "#{country_code}- #{number}"
    human_number << " ext. #{extension}" if extension
    human_number
  end

  # Begin mlightner fork code.

  MIN_LENGTH = 7;
  US_LENGTH = 10;

  COUNTRY_CODES  = %w{
    1   7       20      27      30      31      32      33      34
    36  39      40      41      43      44      45      46      47
    48  49      51      52      53      54      55      56      57
    58  60      61      62      63      64      65      66      81
    82  84      86      90      91      92      93      94      95
    98  212     213     216     218     220     221     222     223
    224 225     226     227     228     229     230     231     232
    233 234     235     236     237     238     239     240     241
    242 243     244     245     246     247     248     249     250
    251 252     253     254     255     256     257     258     260
    261 262     263     264     265     266     267     268     269
    290 291     297     298     299     350     351     352     353
    354 355     356     357     358     359     370     371     372
    373 374     375     376     377     378     380     381     385
    386 387     388     389     420     421     423     500     501
    502 503     504     505     506     507     508     509     590
    591 592     593     594     595     596     597     598     599
    670 672     673     674     675     676     677     678     679
    680 681     682     683     684     685     686     687     688
    689 690     691     692     800     808     850     852     853
    655 856     870     871     872     873     874     878     880
    881 882     886     960     961     962     963     964     965
    966 967     968     970     971     972     973     974     975
    976 977     979     991     992     993     994     995     996
    998
    }

  def self.parse_and_create(raw, assume_us = false, reraise = false)
    raw = raw.strip
    original = raw.dup

    begin
      raise "No number given" unless raw =~ /\d/

      # Check for extension.
      if raw =~ /\s*(?:(?:ext|ex|xt|x)[\s.:]*(\d+))$/i
        extension = $1
        raise "Extension longer than 4 digits: #{extension}" if extension.length > 4
        raw = raw.gsub(/\s*(?:(?:ext|ex|xt|x)[\s.:]*(\d+))$/i, '')
      end

      # Remove non-digits and leading 0
      raw = raw.gsub(/\D/, '')
      raw = raw.gsub(/^[0]+/, '')

      assume_us = true if raw.length == US_LENGTH

      if assume_us
        country_code = 1
        raw = raw.gsub(/^1/, '')
        raise "Invalid US number: #{raw}" if raw.length < US_LENGTH
      else
        # Try to figure out the country code
        (1..3).each do |i|
          possible_code = raw[0,i]
          if COUNTRY_CODES.include?(possible_code)
            #next if (raw.length - possible_code.length) < MIN_LENGTH
            country_code = possible_code
            raw = raw.gsub(/^#{country_code}/, '')
            break
          end
        end
      end # assume_us

      raise "Could not determine country code." unless country_code
      raise "Base phone number is too short: #{raw}" if raw.length < MIN_LENGTH

    rescue Exception => e
      raise "Could not parse phone number: #{e.message}" if reraise
      new(:raw => original, :number => original)
    else
      new(:raw => original, :extension => extension, :country_code => country_code, :number => raw)
    end
  end

  def to_s(delim = '-')
    return number unless valid?
    ret = ""
    if country_code != 1
      ret << "+#{country_code} "
    end
    ret << number.gsub(/([0-9]{1,5})([0-9]{3})([0-9]{4})$/,"\\1#{delim}\\2#{delim}\\3")

    ret << "x#{extension}" if extension
    ret
  end

  def to_basic_s(include_extension = true)
    return number unless valid?
    (include_extension && extension) ? "+#{country_code}#{number}x#{extension}" : "+#{country_code}#{number}"
  end

  def valid?
    (country_code) ? true : false
  end

  def us_number?
    (valid? && country_code == 1) ? true : false
  end

  def international_number?
    (valid? && country_code != 1) ? true : false
  end

end
