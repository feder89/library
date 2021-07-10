import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { OrderConsultComponent } from './order-consult.component';

describe('OrderConsultComponent', () => {
  let component: OrderConsultComponent;
  let fixture: ComponentFixture<OrderConsultComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ OrderConsultComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(OrderConsultComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
