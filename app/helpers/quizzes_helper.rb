module QuizzesHelper
    
    def fix_answer_array(input)
        a = Float::INFINITY
        b = -1*a
        take_out_inf = input.map {|flap| flap == a ? "Infinity" : flap}
        take_out_neg = take_out_inf.map {|flap| flap == b ? "-Infinity" : flap}
        correct_array_fixed = take_out_neg.each{|f| f.gsub(/\s+/, "").gsub(/[()]/, "").downcase! if f.is_a?(String)}
    end
end
