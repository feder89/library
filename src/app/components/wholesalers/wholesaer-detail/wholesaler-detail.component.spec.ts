import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { WholesalerDetailComponent } from './wholesaler-detail.component';

describe('WholesaerDetailComponent', () => {
  let component: WholesalerDetailComponent;
  let fixture: ComponentFixture<WholesalerDetailComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ WholesalerDetailComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(WholesalerDetailComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
