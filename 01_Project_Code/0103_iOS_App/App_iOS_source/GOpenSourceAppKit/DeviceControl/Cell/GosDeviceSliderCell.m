//
//  GosDeviceSliderCell.m
//  GOpenSource_AppKit
//
//  Created by danly on 2017/2/9.
//  Copyright © 2017年 Gizwits. All rights reserved.
//

// 注：本类中 当前步值：表示的是当前滑块需要滑动到滚动条的位置

#import "GosDeviceSliderCell.h"
#import "NSString+Rounding.h"

@interface GosDeviceSliderCell()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *valueLabel;

@property (weak, nonatomic) IBOutlet UILabel *minLabel;
@property (weak, nonatomic) IBOutlet UILabel *maxLabel;
@property (weak, nonatomic) IBOutlet UISlider *slide;

// 存储小数点后保留的有效位个数
@property (nonatomic, assign) NSInteger decimalLength;
// 存储当前滑动条滑动的步数
@property (nonatomic, assign) NSInteger currentStep;

@end

@implementation GosDeviceSliderCell

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:NO animated:animated];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    
}

#pragma mark - updateUI
// 为控件的所有属性赋值之后，必须调用这个方法才能正常显示数据
- (void)updateUI
{
    // 计算小数点后面保留的有效位位数
    self.decimalLength = [NSString getDecimalPointLengthByRadio:_radio andAddition:_addition];
    
    // 设置滚动条
    [self setupSlide];
    // 显示当前数据点值
    [self updateUIByValue];
}

// 设置滚动条
- (void)setupSlide
{
    // 设置滚动条的范围从 min~max
    self.slide.minimumValue = _min;
    self.slide.maximumValue = _max;
}

// 更新 数据点值Label
- (void)updateLabelByValue
{
    NSLog(@"title = %@", self.title);
    NSLog(@"有效位数 = %zd", self.decimalLength);
    // 将数据点值保留指定小数点后有效位显示到界面
    NSLog(@"计算后的value = %f", _value);
    self.valueLabel.text = [NSString stringWithFormat:@"%@", [NSString getFormateStr:_value afterPoint:self.decimalLength]];
}


/**
 根据当前数据点值更新界面
 */
- (void)updateUIByValue
{
    [self getCurrentStep];
    [self getValueByCurrentStep];
    [self updateLabelByValue];
    // 滑动滑块
    self.slide.value = _currentStep;
}


/**
 根据当前步值更新界面
 */
- (void)updateUIByStep
{
    [self getCurrentStepByStep:self.slide.value];
    [self getValueByCurrentStep];
    [self updateLabelByValue];
}

#pragma mark - Action
// 滑块滑动过程一直调用该方法
- (IBAction)slideChanging
{
    NSLog(@"正在滑动");
    [self updateUIByStep];
}

// 滑块滑动停止时调用
- (IBAction)slideChanged
{
    [self updateUIByStep];
    self.slide.value = _currentStep;
    
    if ([self.delegate respondsToSelector:@selector(deviceSlideCell:updateValue:)])
    {
        [self.delegate deviceSlideCell:self updateValue:_value];
    }
}

#pragma mark - 当前步值与当前数据点值之间的转换
/**
 根据当前的数据点值获取取整后的当前步值：
 value与currentStep的关系式: value = radio * currentStep(滚动条的当前值) + addition;
 
 _value: 当前数据点值
 */
- (void)getCurrentStep
{
    // 获取当前数据点值精确对应的滚动条滑动值
    CGFloat tempCurrentStep = (_value - _addition.doubleValue) / _radio.doubleValue;

    // 将滚动条滑动值取整
    [self getCurrentStepByStep:tempCurrentStep];
}


/**
 根据浮点型的步值四舍五入取整获得整型步值
 */
- (void)getCurrentStepByStep:(CGFloat)step
{
    _currentStep = [NSString getFormateStr:step afterPoint:0].integerValue;
}


/**
 根据当前步值取得相应的数据点值
 value与currentStep的关系式: value = radio * currentStep(滚动条的当前值) + addition;
 
 @param currentStep 当前步值
 */
- (void)getValueByCurrentStep
{
    _value = (_radio.doubleValue * (CGFloat)_currentStep) + _addition.doubleValue;
}

#pragma mark- Properity
- (void)setTitle:(NSString *)title
{
    _title = title;
    self.titleLabel.text = title;
}

//- (void)setValue:(CGFloat)value
//{
//    NSLog(@"传入的value = %f", value);
//    _value = value;
//}

- (void)setMaxValue:(NSString *)maxValue
{
    _maxValue = maxValue;
    self.maxLabel.text = maxValue;
}

- (void)setMinValue:(NSString *)minValue
{
    _minValue = minValue;
    self.minLabel.text = minValue;
}

@end
